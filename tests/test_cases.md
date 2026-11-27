# Checkers — Test Cases & Automated Suites

## Manual & Integration Scenarios

| # | Scenario | Expected result |
|---:|---|---|
| 1 | Start a new game (American 8×8) | 12 Red pawns, 12 Black pawns, 8 empty playable squares; Black moves first |
| 2 | Start a new game (International 10×10) | 20 Red pawns (`1–20`), 10 empty (`21–30`), 20 Black pawns (`31–50`); Black moves first |
| 3 | Automatic 180° board rotation | Black's turn shows rows `0..7`/`0..9` (Black at bottom); Red's turn rotates 180° to rows `7..0`/`9..0` (Red at bottom) including the side-by-side square-number map |
| 4 | Valid normal move by each side | Piece moves one diagonal step forward (or any unobstructed diagonal distance for International Flying Kings); prints `Move played: <start>-<dest>` |
| 5 | Invalid start / destination input | Out-of-range (`1–32` or `1–50`), empty, opponent piece, or illegal destination re-prompts cleanly without mutating `board`; entering `0` at destination reselects piece |
| 6 | Multi-jump capture & path previews | Selecting a capturing piece lists all legal 1st-hop landing squares *and* full capture paths (e.g. `21x14x5`, `21x14x7`), stepping through each hop with refreshed board & hints |
| 7 | American promotion during capture | Reaching the king-row promotes the pawn to King and **ends the turn immediately** (per `american_checkers.pdf`) |
| 8 | International backward pawn capture | Men can jump opponent pieces both forward and backward |
| 9 | International Flying King capture | Flying King can jump an opponent at any distance and land on **any** empty square beyond along that diagonal; all legal landing squares are listed |
| 10 | International Maximum Capture rule | When multiple capture sequences exist, only pieces and landing squares achieving the maximum capture count are listed and accepted |
| 11 | International deferred removal & promotion | Jumped pieces stay marked (`x`) until the chain ends (cannot be jumped twice); pawns promote only if they end their turn on the king-row |
| 12 | Win detection (elimination & trap) | Detects both 0 remaining opponent pieces and 0 legal moves (Figure 9 trap win), announces Player 1/2 winner, and exits |

## Rulesets Available at Startup

1. **American / English Checkers (8×8, Official):** Mandatory initial & chain captures, forward-only pawn captures, promotion ends turn.
2. **International Checkers (10×10):** 50 squares, 20 pieces/side, backward pawn captures, Flying Kings, deferred removal, maximum capture rule, end-of-turn promotion.
3. **American / English Casual (8×8):** Optional initial capture, mandatory follow-up chain captures.

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
| [test_new_features.asm](./test_new_features.asm) | 10×10 coords (`N1`), 10×10 init & 180° rotation (`N2`), International backward pawn capture (`N3`), Flying King normal (`N4`) & multi-landing capture (`N5`), Maximum Capture rule (`N6`), American promotion-ends-turn (`N7`), multi-jump path preview & immutability (`N8`) | Non-interactive |

## Test discipline

- For every invalid move or query helper, verify that `board` and `captured_mask` stay unchanged.
- Re-run all 8 harnesses plus assemble `src/main.asm` after any shared-interface change.
