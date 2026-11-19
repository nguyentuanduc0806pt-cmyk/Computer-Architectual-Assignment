# Checkers — Essential Test Cases

Use these as manual test scenarios while implementing and integrating the modules.

| # | Scenario | Expected result |
|---:|---|---|
| 1 | Start a new game | 12 Red pawns, 12 Black pawns, 8 empty playable squares; Black moves first |
| 2 | Print the board | Display all 8 rows and 8 columns; inaccessible squares are shown but not stored |
| 3 | Valid normal move by each side | Piece moves one diagonal step forward to an empty playable square |
| 4 | Starting square is empty | Reject the move; board remains unchanged |
| 5 | Starting square belongs to the other player | Reject the move; board remains unchanged |
| 6 | Destination is occupied | Reject the move; board remains unchanged |
| 7 | Pawn moves in the wrong direction | Reject the move; board remains unchanged |
| 8 | Valid capture | Mover lands beyond the opponent piece; captured piece is removed |
| 9 | Invalid capture | Reject the move; board remains unchanged |
| 10 | King moves backwards | Permit legal backward diagonal movement |
| 11 | Multiple captures are available in sequence | The same piece continues the chain until no further capture is available |
| 12 | Pawn reaches final row during a capture | Promote immediately; the new king may continue the same chain backwards |
| 13 | Opponent has no remaining pieces | Announce the winner and terminate the game |

## Rule-scope note

For the bare-minimum assignment, capturing an opponent piece is not required whenever an initial capture is available. However, once a capture has been made, a possible follow-up capture in the same chain must be taken. Enforcing the initial mandatory-capture rule is listed as an extra task in the assignment.

## Test discipline

- For every invalid move, verify that all 32 board bytes remain unchanged.
- Test each module independently before integrating it.
- Re-run the complete test set after changes to shared interfaces.
