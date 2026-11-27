# Checkers — Test Cases & Automated Suites

## Manual & Integration Scenarios

| # | Scenario | Expected result |
|---:|---|---|
| 1 | Start a new game | 12 Red pawns, 12 Black pawns, 8 empty playable squares; Black moves first |
| 2 | Print the board | Boxed 8×8 grid with coordinates, side-by-side `1–32` reference map, legend, and live piece counts |
| 3 | Valid normal move by each side | Piece moves one diagonal step forward; prints `Move played: <start>-<dest>` |
| 4 | Starting square is empty or out of `1–32` | Clear error message; re-prompts without touching the board |
| 5 | Starting square belongs to the opponent | Clear error message; re-prompts without touching the board |
| 6 | Destination is occupied or illegal | Clear error message; re-prompts destination (or enter `0` to pick another piece); board unchanged |
| 7 | Pawn moves in the wrong direction | Move rejected; board remains unchanged |
| 8 | Valid capture | Mover jumps opponent, captured piece is removed, prints `Captured <Side>'s piece! (<start>x<dest>)` |
| 9 | Invalid capture | Rejected; all 32 board bytes remain unchanged |
| 10 | King moves and captures backwards | Legal backward diagonal steps and jumps are allowed |
| 11 | Multi-jump chain capture | Board refreshes, available landing squares are listed, same piece keeps jumping until no capture remains |
| 12 | Pawn reaches final row during a capture | Promoted immediately with promotion notice; new King can keep chaining backwards on the same turn |
| 13 | Opponent has no remaining pieces | Prints elimination reason, final board, winner banner (with Player 1/2 + color), and exits |
| 14 | Player 1 chooses Red or Black | Player 1 picks side at startup; Black still moves first; turn & win banners show the right Player 1/2 label |
| 15 | Mandatory initial capture (Official mode) | When any piece can capture, lists capturing pieces and blocks non-capturing pieces/moves |
| 16 | Optional initial capture (Casual mode) | Allows normal moves even when a capture exists, while still enforcing follow-up chain captures |
| 17 | Selected-piece legal moves & reselect (`0`) | Selecting a piece shows its type and legal move/capture squares; blocked pieces are rejected right away; entering `0` returns to piece selection |
| 18 | Opponent trapped with 0 legal moves (Figure 9) | Even with pieces still on the board, detects 0 normal moves and 0 captures, announces trap win, and exits |

## Rule-scope note

The game supports both rulesets at startup:
- **Official English Checkers (Option 1):** enforces mandatory initial capture *and* mandatory chain captures.
- **Casual Mode (Option 2):** matches the assignment's bare-minimum rule (initial capture optional, follow-up chain capture mandatory).

## Automated Unit Test Harnesses (`tests/`)

Run each file individually in MARS 4.5 (with *Assemble all files in directory* **off** and *Start at global `main`* **on**):

| File | Covers | Notes |
|---|---|---|
| [test_member_a.asm](./test_member_a.asm) | `init_board`, `print_board`, `square_to_coord` ↔ `coord_to_square` (1..32), `validate_normal_move`, `apply_normal_move` | Non-interactive |
| [test_member_b.asm](./test_member_b.asm) | `validate_capture` (`C1–C10`) + board immutability | Non-interactive |
| [test_apply_capture.asm](./test_apply_capture.asm) | `apply_capture` valid 3-byte update & invalid no-op | Non-interactive |
| [test_check_capture.asm](./test_check_capture.asm) | `check_capture` (`CC1–CC5`, pawns & kings) | Non-interactive |
| [test_check_winner.asm](./test_check_winner.asm) | `check_winner` (`W1–W5`) | Non-interactive |
| [test_chain_capture.asm](./test_chain_capture.asm) | `chain_capture` follow-up jump (`14 → 7`) + board refresh & hints | Interactive (enter `7`) |
| [test_tier1_features.asm](./test_tier1_features.asm) | `check_promotion`, `has_normal_move`, `print_normal_moves`, `has_any_capture`, `print_capture_moves`, `print_mandatory_capture_pieces`, Figure 9 trap detection, immutability (`T1–T6`) | Non-interactive |

## Test discipline

- For every invalid move or query helper, verify that all 32 bytes of `board` stay unchanged.
- Re-run all 7 harnesses plus an end-to-end game in `src/main.asm` after any shared-interface change.
