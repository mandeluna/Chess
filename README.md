# Chess

An iOS chess app originally ported to Objective-C from Andreas Raab's Squeak implementation, and incrementally modernized toward a Swift/SwiftUI front-end with a UCI-compatible engine.

## Credits

The chess engine at the core of this project is based on the work of **Andreas Raab**, originally written in Smalltalk for the [Squeak](https://squeak.org) environment. His implementation provided the foundation for the move generator, board evaluation, and game logic that still powers this app.

## Project Structure

| Directory / Target | Description |
|---|---|
| `Classes/` | Original Objective-C engine and `ViewController`-based UI |
| `ChessEngine/` | Swift wrapper around the Objective-C engine exposing a UCI interface |
| `ChessEngineTool/` | Command-line UCI tool for engine testing |
| `ChessEngineFrameworkTests/` | Unit and integration tests for the engine |
| `Shambolic/` | SwiftUI front-end (active development target) |
| `ShambolicTests/` | Tests for the SwiftUI target |

## Architecture

The engine communicates via [UCI (Universal Chess Interface)](https://www.chessprogramming.org/UCI), exchanging board state in [FEN (Forsyth–Edwards Notation)](https://www.chessprogramming.org/Forsyth-Edwards_Notation). The goal is to keep the engine and UI fully decoupled — the SwiftUI layer treats the engine as a black box that accepts FEN positions and returns moves.

## Status

- Engine passes the UCI test suite
- SwiftUI board view under active development
- `ViewController`-based UI (legacy) being retired

## Requirements

- Xcode 16+
- iOS 17+ (SwiftUI target)
- macOS (for command-line engine tool)

## License

See [CREDITS](#credits). Engine logic derived from Andreas Raab's original Squeak chess implementation.
