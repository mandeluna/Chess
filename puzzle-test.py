#!/usr/bin/env python3
"""
puzzle-test.py — Run Chamonix against Lichess puzzles from a SQLite database.

Usage:
    python3 puzzle-test.py [options]

Options:
    --engine PATH       Path to UCI engine binary
                        (default: Chamonix/Products/usr/local/bin/Chamonix)
    --database PATH     Path to Lichess SQLite puzzle database
                        (default: ../chess/Chess Data/lichess)
    --theme THEME       Filter puzzles by theme (e.g. mateIn1, mateIn2, fork)
                        Can be specified multiple times; puzzles matching ANY
                        theme are included.  Omit for all themes.
    --count N           Number of puzzles to run (default: 100)
    --movetime MS       Engine thinking time per move in milliseconds (default: 1000)
    --min-rating R      Minimum puzzle rating (default: no filter)
    --max-rating R      Maximum puzzle rating (default: no filter)
    --log FILE          Write results to this file in addition to stdout
                        (default: puzzle-results-<timestamp>.log)
    --seed N            Random seed for reproducible puzzle selection
"""

import argparse
import datetime
import os
import random
import sqlite3
import subprocess
import sys
import threading
import time


# ---------------------------------------------------------------------------
# Engine communication
# ---------------------------------------------------------------------------

class UCIEngine:
    def __init__(self, path):
        self.proc = subprocess.Popen(
            [path],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            text=True,
            bufsize=1,
        )
        self._lock = threading.Lock()

    def is_alive(self):
        return self.proc.poll() is None

    def send(self, command):
        if not self.is_alive():
            raise BrokenPipeError("Engine process has exited")
        self.proc.stdin.write(command + "\n")
        self.proc.stdin.flush()

    def read_until(self, keyword, timeout=10.0):
        """Read lines until one contains keyword; return all lines read."""
        lines = []
        deadline = time.monotonic() + timeout
        while time.monotonic() < deadline:
            # Non-blocking readline via select would be cleaner, but a short
            # readline timeout achieved by making the pipe line-buffered works
            # on macOS.
            self.proc.stdout.flush()
            line = self.proc.stdout.readline()
            if not line:
                break
            line = line.rstrip()
            lines.append(line)
            if keyword in line:
                return lines
        return lines  # timed out

    def init(self):
        self.send("uci")
        self.read_until("uciok", timeout=5.0)
        self.send("isready")
        self.read_until("readyok", timeout=10.0)

    def new_game(self):
        self.send("ucinewgame")
        self.send("isready")
        self.read_until("readyok", timeout=10.0)

    def best_move(self, fen, moves_played, movetime_ms):
        """
        Set up position from FEN + list of UCI moves already played,
        then ask the engine for a move.  Returns the bestmove string or None.
        """
        moves_part = ""
        if moves_played:
            moves_part = " moves " + " ".join(moves_played)
        self.send(f"position fen {fen}{moves_part}")
        self.send(f"go movetime {movetime_ms}")
        lines = self.read_until("bestmove", timeout=movetime_ms / 1000.0 + 5.0)
        for line in reversed(lines):
            if line.startswith("bestmove"):
                parts = line.split()
                if len(parts) >= 2 and parts[1] != "(none)":
                    return parts[1]
        return None

    def quit(self):
        try:
            self.send("quit")
            self.proc.wait(timeout=3.0)
        except Exception:
            self.proc.kill()


# ---------------------------------------------------------------------------
# Puzzle logic
# ---------------------------------------------------------------------------

def run_puzzle(engine, fen, solution_moves, movetime_ms):
    """
    Run a single puzzle.

    solution_moves: list of UCI move strings from the database.
        Index 0  — opponent's setup move (already applied to reach the puzzle).
        Index 1  — engine's first expected move.
        Index 2  — opponent's response (played by the script).
        Index 3  — engine's second expected move.
        … and so on.

    Returns (passed: bool, engine_moves: list[str], expected_moves: list[str])
    """
    # The position fed to the engine includes the setup move.
    setup_move = solution_moves[0]
    expected = solution_moves[1:]   # alternating: engine, script, engine, …

    moves_played = [setup_move]     # moves appended to the FEN position command
    engine_moves = []
    expected_engine_moves = []

    i = 0  # index into expected[]
    while i < len(expected):
        # Engine's turn
        expected_engine_move = expected[i]
        expected_engine_moves.append(expected_engine_move)

        actual = engine.best_move(fen, moves_played, movetime_ms)
        engine_moves.append(actual if actual else "(none)")

        if actual != expected_engine_move:
            return False, engine_moves, expected_engine_moves

        moves_played.append(actual)
        i += 1

        # Opponent's response (if any)
        if i < len(expected):
            opponent_move = expected[i]
            moves_played.append(opponent_move)
            i += 1

    return True, engine_moves, expected_engine_moves


# ---------------------------------------------------------------------------
# Database
# ---------------------------------------------------------------------------

def fetch_puzzles(db_path, themes, count, min_rating, max_rating, seed):
    conn = sqlite3.connect(db_path)
    cur = conn.cursor()

    conditions = []
    params = []

    if themes:
        theme_clauses = " OR ".join(["Themes LIKE ?" for _ in themes])
        conditions.append(f"({theme_clauses})")
        for t in themes:
            params.append(f"%{t}%")

    if min_rating is not None:
        conditions.append("CAST(Rating AS INTEGER) >= ?")
        params.append(min_rating)

    if max_rating is not None:
        conditions.append("CAST(Rating AS INTEGER) <= ?")
        params.append(max_rating)

    where = f"WHERE {' AND '.join(conditions)}" if conditions else ""

    # Use SQLite's random() for an efficient random sample without loading
    # the whole table.  We overfetch slightly to allow for malformed rows.
    fetch_n = count * 2
    query = f"SELECT PuzzleId, FEN, Moves, Themes, Rating FROM puzzle {where} ORDER BY RANDOM() LIMIT ?"
    params.append(fetch_n)

    cur.execute(query, params)
    rows = cur.fetchall()
    conn.close()

    if seed is not None:
        random.seed(seed)
        random.shuffle(rows)

    valid = []
    for row in rows:
        puzzle_id, fen, moves_str, puzzle_themes, rating = row
        moves = moves_str.strip().split()
        if len(moves) < 2:
            continue  # need at least a setup move + one engine move
        valid.append((puzzle_id, fen, moves, puzzle_themes, rating))
        if len(valid) >= count:
            break

    return valid


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    default_engine = os.path.join(script_dir, "Chamonix", "Products", "usr", "local", "bin", "Chamonix")
    default_db = os.path.join(os.path.dirname(script_dir), "chess", "Chess Data", "lichess")

    parser = argparse.ArgumentParser(description="Test a UCI engine against Lichess puzzles.")
    parser.add_argument("--engine", default=default_engine, help="Path to UCI engine binary")
    parser.add_argument("--database", default=default_db, help="Path to Lichess SQLite puzzle database")
    parser.add_argument("--theme", action="append", dest="themes", metavar="THEME",
                        help="Filter by theme (repeatable); omit for all themes")
    parser.add_argument("--count", type=int, default=100, help="Number of puzzles to run")
    parser.add_argument("--movetime", type=int, default=1000, help="Engine thinking time per move (ms)")
    parser.add_argument("--min-rating", type=int, default=None)
    parser.add_argument("--max-rating", type=int, default=None)
    parser.add_argument("--log", default=None, help="Log file path (default: auto-named)")
    parser.add_argument("--seed", type=int, default=None, help="Random seed")
    args = parser.parse_args()

    timestamp = datetime.datetime.now().strftime("%Y-%m-%d_%H%M%S")
    log_path = args.log or f"puzzle-results-{timestamp}.log"

    def log(msg=""):
        print(msg)
        with open(log_path, "a") as f:
            f.write(msg + "\n")

    # Header
    theme_label = ", ".join(args.themes) if args.themes else "all"
    log(f"=== Puzzle Test {timestamp} ===")
    log(f"Engine:   {args.engine}")
    log(f"Database: {args.database}")
    log(f"Themes:   {theme_label}")
    log(f"Count:    {args.count}")
    log(f"Movetime: {args.movetime} ms")
    if args.min_rating or args.max_rating:
        log(f"Rating:   {args.min_rating or '*'} – {args.max_rating or '*'}")
    log()

    # Fetch puzzles
    log("Fetching puzzles from database…")
    puzzles = fetch_puzzles(
        args.database,
        args.themes or [],
        args.count,
        args.min_rating,
        args.max_rating,
        args.seed,
    )
    if not puzzles:
        log("No puzzles found matching the given criteria.")
        sys.exit(1)
    log(f"Selected {len(puzzles)} puzzles.\n")

    # Start engine
    log("Starting engine…")
    engine = UCIEngine(args.engine)
    engine.init()
    log("Engine ready.\n")

    log(f"{'#':>4}  {'PuzzleId':<8}  {'Rating':>6}  {'Result':<6}  {'Engine':^20}  {'Expected':^20}  Themes")
    log("-" * 100)

    passed = 0
    failed = 0
    errors = 0

    for idx, (puzzle_id, fen, moves, themes, rating) in enumerate(puzzles, 1):
        try:
            if not engine.is_alive():
                log(f"  [engine crashed — restarting]")
                engine = UCIEngine(args.engine)
                engine.init()
            engine.new_game()
            ok, engine_moves, expected_moves = run_puzzle(engine, fen, moves, args.movetime)
        except Exception as e:
            result = "ERROR"
            errors += 1
            log(f"{idx:>4}  {puzzle_id:<8}  {rating:>6}  {result:<6}  {str(e)}")
            continue

        if ok:
            passed += 1
            result = "PASS"
        else:
            failed += 1
            result = "FAIL"

        engine_str = " ".join(engine_moves)
        expected_str = " ".join(expected_moves)
        themes_short = themes[:40] if themes else ""
        log(f"{idx:>4}  {puzzle_id:<8}  {rating:>6}  {result:<6}  {engine_str:<20}  {expected_str:<20}  {themes_short}")

    engine.quit()

    total = passed + failed + errors
    pct = 100.0 * passed / total if total > 0 else 0.0
    log()
    log("=" * 60)
    log(f"Results: {passed}/{total} passed ({pct:.1f}%)")
    if errors:
        log(f"Errors:  {errors}")
    log(f"Log:     {log_path}")


if __name__ == "__main__":
    main()
