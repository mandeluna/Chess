# To do

0. UILayout and basic gameplay
   * switch sides to play as black
   * show status string (checkmate etc.)
   * improve calculation of score (who is winning?)
   * show captures (and basic piece score)
   * ipad status bar obscures top of board

1. Find and fix memory leaks in ChessPlayer copying

2. Fix unhandled exceptions in recycleMoveList (threading issue?)

3. Add time manager class and behaviour.

4. Improve the board position evaluation logic.

5. Config options for transposition table size and history table logic. Test efficacy of this as well as other engine parameter changes.

6. Implement a movelist view controller that supports PGN export, import & selecting different moves.

7. Maintain a log of board positions and PGN notation for games played (where?)

8. Improve reporting of UCI info strings, especially depth reporting.

9. Measure performance of move generator. Consider bit board representation & encoded ChessMove objects

10. Design a new GUI and implement with Swift UI.
    a) Feature set
        - timers
         - undo/redo
         - set board position from FEN string or PGN
         - engine interface (UCI or API?)
    b) Mockups
        - navigation
        - settings
    c) Justification
        - en croissant / pawn appetit seem to have some conflict & react front-end is broken in many places
        - other UIs are either Windows-only or horribly dated Qt things
        - nothing works on mobile
        - what about Android?
    d) Technical Design
        - Move List View Controller

11. Port game engine to Linux/BSD (GNUStep? Swift? Rust?)

12. Build an ActivityPUB social game.

13. Print the board in a more compact ASCII notation

14. Support a different threading model

15. Move analysis from opening book / neural network (NNUE)

16. Neural network training from chess puzzles and game databases

## Release Plan

0.1 - 2025-08-25: first version able to complete a UCI match against Stockfish
0.2 - TBD: variable Transposition Table
0.3 - TBD: History Table support 
0.4 - TBD: board evaluation enhancements
0.5 - TBD: time management system

The easiest options to test are changing the TT size, adding history table entries.

It should also be a high priority to fix the castling bugs and test to ensure the internal state is consistent.

## Learning Plan

What are we trying to accomplish here?

There is a lot of stuff I don't understand and a big part of this is to help me become a better chess player
and generally improve my understanding of the state of the art.

Concepts I would like to understand better:

1. What are the advantages of switching to a bitboard representation?

2. What is iterative deepening?

3. What should we be doing with Principle Varation vectors?

4. How chess engines use opening books to improve gameplay

5. How a neural network can improve on the basic opening book approach

## Some old notes

* add game clocks
* provide option for timed game play
* add move lists
* show captured pieces
* show labels for online opponents
* status icon to indicate opponent is online
* status icon to indicate opponent has voice chat enabled
* provide button to enable/disable voice chat (mute local, mute remote)
* provide indicator showing voice chat volume during game
* save game state when quitting
* restore game state on startup
* provide option to reconnect with opponent restoring saved game in progress
* add support for Game Center sessions (GKMatch)
* set up leaderboards and tournament invitations
* provide different theme choices for the gameboard and players
* fix layout of subviews when screen is rotated into landscape mode

* negotiate which player will be white
    * at the start of the game, both players have the white pieces facing them
    * once the network negotiation is complete, we have an alert in NSStreamEventOpenCompleted
    * need this for BT sessions & GKMatch sessions
    * game state should be as follows:
    1. Initial state == invalid: black player undefined, white player specified twice
    * We need to enforce that white goes first,
    * that one player cannot move when it's another player's turn (can we reuse isThinking flag for computer play?)
    * We should keep track of the time spent on each move by each player
    ** if clocks get out of sync, we need a way to resynchronize them
    * Assume that each player's computer will enforce the legality of each move
    * We should encode # check and ++ double attack (there are a few operators we need - check wikipedia)
    * We need to notify users of checkmate and stalemate
    * If the board state is repeated more than 3 times (or is it 3 times or more) we should offer the opportunity to draw the game
    ** in general players need options to agree on a draw, or to resign


