# To do

Some ideas I've had in no particular order. 

1. Test the castling state -- I noticed the other day it let me do an illegal castling move (while my rook was under threat).
   The FEN string should show the correct KQkq string based on an appropriate mix of board positions.

2. Test the halfmove clock and fullmove number -- as above, the appropriate state should be reflected in the FEN string.

3. Ensure the above are working with undo/redo.

4. Maintain a log of board positions and PGN notation for games played.

5. Add time manager class and behaviour.

6. Improve the board position evaluation logic.

7. Config options for transposition table size.

8. Improve reporting of UCI info strings, especially depth reporting.

9. Implment history table logic. Test efficacy of this as well as other engine parameter changes.

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

11. Port game engine to Linux.

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
