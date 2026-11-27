# Capture Module — CO2008 Checkers

**Owner:** Member B  
**Source file:** [capture.asm](./capture.asm)

---

## 1. Overview

This module handles all capture validation, execution, multi-jump chaining, Flying King captures, Maximum Capture enforcement, and complete capture-path previews for both rulesets:
- **American / English Checkers (`ruleset == 0`, 8×8):**
  - Pawns jump 2 squares diagonally forward only; Kings jump 2 squares diagonally forward or backward.
  - Any legal capturing piece and jump sequence may be chosen (no maximum-capture restriction), and a jumping piece must continue until no further jump remains.
  - Promotion on the king-row **ends the turn immediately**.
- **International Checkers (`ruleset == 1`, 10×10):**
  - Pawns jump 2 squares diagonally **both forward and backward**.
  - **Flying Kings** jump an opponent piece at any distance along a diagonal and may land on **any empty square beyond it** before another piece or the board edge.
  - **Maximum Capture Rule:** Players must choose a piece and capture path that captures the **maximum** number of opponent pieces.
  - **Deferred Removal:** Jumped pieces are marked in `captured_mask` (cannot be jumped twice) and removed together via `finalize_captured_pieces` once the chain completes.
  - Promotion occurs only if a pawn **ends its turn** on the king-row.

---

## 2. Core & Query Procedures

| Procedure | Inputs | Output / Behavior |
|---|---|---|
| `find_captured_square` | `$a0 = start`, `$a1 = dest`, `$a2 = player` | Read-only core validator for American short jumps, International pawn forward/backward jumps, and International Flying King rays. Returns captured square (`1..num_squares`) or `0` if invalid. |
| `validate_capture` | `$a0 = start`, `$a1 = dest`, `$a2 = player` | Wrapper over `find_captured_square`; returns `$v0 = 1` if valid, `0` otherwise. |
| `apply_capture` | `$a0 = start`, `$a1 = dest` (reads `current_player`) | Moves piece `start → dest`. Removes captured piece immediately (American) or marks `captured_mask[cap_sq-1] = 1` during an active International chain. |
| `finalize_captured_pieces` | *(none)* | Clears all `captured_mask`-marked pieces from `board[]`, clears `captured_mask[]`, and resets `in_capture_chain = 0`. |
| `has_capture_from` | `$a0 = sq`, `$a1 = player` | Checks all 4 diagonal directions (including Flying King rays in International mode). Read-only. |
| `check_capture` | `$a0 = sq` (reads `current_player`) | Tail-call wrapper to `has_capture_from`. |
| `has_any_capture` | `$a0 = player` | Scans `1..num_squares` for any piece of `player` that can capture. |
| `max_capture_from` | `$a0 = sq`, `$a1 = player` | Recursive DFS returning the maximum number of pieces capturable in one turn starting from `sq`. Fully restores `board` and `captured_mask`. |
| `max_capture_for_player` | `$a0 = player` | Scans `1..num_squares` and returns the global maximum capture count for `player`. |
| `is_capture_allowed` | `$a0 = start`, `$a1 = dest`, `$a2 = player` | Validates the hop and (when `ruleset == 1`) verifies `1 + max_capture_from(dest) == max_capture_from(start)`. |
| `print_capture_moves` | `$a0 = sq`, `$a1 = player` | Prints all legal 1st-hop capture landing squares (including all Flying King landings along each diagonal, filtered by `is_capture_allowed`). Returns count in `$v0`. |
| `print_capture_paths` | `$a0 = sq`, `$a1 = player` | Recursive DFS (`pcp_dfs`) that prints every complete legal multi-jump chain (e.g. `21x14x5`, `21x14x7`), filtered to maximum-length chains in International mode. Restores `board` & `captured_mask`. |
| `print_mandatory_capture_pieces` | `$a0 = player` | Prints all pieces that can capture (American) or all pieces achieving the global maximum capture count (International). Returns count in `$v0`. |
| `chain_capture` | `$a0 = cur_sq` | Runs the interactive multi-jump loop: refreshes the board, lists all available landing squares and remaining capture paths, validates via `is_capture_allowed`, executes & prints feedback, and handles American promotion-ends-turn vs. International deferred promotion. Returns `$v0 = 1` and `$v1 = final_sq`. |
| `print_capture_feedback` | `$a0 = start`, `$a1 = dest`, `$a2 = player` | Prints `Captured <Side>'s piece! (<start>x<dest>)`. |
