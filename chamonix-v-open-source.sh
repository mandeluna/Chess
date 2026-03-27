#!/bin/bash
# Round-robin tournament: Chamonix vs open-source engines.
# Opponents: Pulse (~1600 ELO, Java), Sunfish (~1400 ELO, Python),
#            Vice (~1800 ELO, C), Rustic Alpha 3 (~1750 ELO, Rust)
# Run after build-test-engines.sh has populated ./test-engines/.
#
# Usage:
#   bash chamonix-v-open-source.sh [blitz|ccrl] [games-per-pair]
#
#   blitz  tc=10+0.1  — fast, ~1 min/game, good for bulk ELO estimation (default)
#   ccrl   tc=40/900  — CCRL 40/15 conditions, ~20 min/game, use a small game count

MODE=${1:-blitz}
GAMES=${2:-200}

ENGINE_DIR="$(pwd)/test-engines"
CHAMONIX="$(pwd)/Chamonix/Products/usr/local/bin/Chamonix"
LOG="cutechess-open-source-$(date +%Y-%m-%d_%H%M%S).log"
PGN="games-open-source-$(date +%Y-%m-%d).pgn"

case "$MODE" in
    ccrl) TC="40/900" ; MARGIN=1000 ;;
    *)    TC="10+0.1" ; MARGIN=500  ;;
esac

# Sanity checks
for f in "$CHAMONIX" "$ENGINE_DIR/pulse.jar" "$ENGINE_DIR/sunfish/sunfish_nnue.py" \
          "$ENGINE_DIR/vice" "$ENGINE_DIR/rustic"; do
    if [ ! -f "$f" ]; then
        echo "Missing: $f"
        echo "Run build-test-engines.sh first."
        exit 1
    fi
done

echo "Starting tournament: Chamonix vs Pulse / Sunfish / Vice / Rustic"
echo "  Mode: $MODE  tc=$TC  $GAMES games per pair"
echo "  Log: $LOG  PGN: $PGN"
echo ""

cutechess-cli \
    -engine name=Chamonix \
            cmd="$CHAMONIX" \
            proto=uci \
            option.Hash=256 \
    -engine name=Pulse \
            cmd=java \
            arg=-jar \
            arg="$ENGINE_DIR/pulse.jar" \
            proto=uci \
    -engine name=Sunfish \
            cmd=python3 \
            arg="$ENGINE_DIR/sunfish/sunfish_nnue.py" \
            proto=uci \
    -engine name=Vice \
            cmd="$ENGINE_DIR/vice" \
            proto=uci \
    -engine name=Rustic \
            cmd="$ENGINE_DIR/rustic" \
            proto=uci \
    -each tc="$TC" timemargin=$MARGIN \
    -openings file=Modern.pgn order=random plies=12 \
    -games "$GAMES" \
    -repeat \
    -pgnout "$PGN" \
    -recover \
    -ratinginterval 10 \
    2>&1 | tee "$LOG"
