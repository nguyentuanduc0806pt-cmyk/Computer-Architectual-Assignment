# Capture Module — CO2008 Checkers

**Owner:** Member B  
**Source file:** [capture.asm](./capture.asm)

---

## 1. Overview

This module handles everything related to jumping and capturing pieces in English Checkers:
- Validating a 2-square diagonal jump (`validate_capture`)
- Executing the jump and removing the jumped piece (`apply_capture`)
- Checking whether a piece can jump (`check_capture`, `has_capture_from`) or whether any piece of a player can jump (`has_any_capture`)
- Running mandatory chain captures (`chain_capture`)
- Printing available jump targets, mandatory capturing pieces, and standard capture notation (`print_capture_moves`, `print_mandatory_capture_pieces`, `print_capture_feedback`)

It uses the shared 32-byte `board` array and `current_player` declared in [board.asm](./board.asm), where square `n` (`1..32`) maps to `board[n - 1]`.

---

## 2. Capture Rules

A jump is valid when:
1. The starting square holds a piece belonging to the moving player.
2. The destination is empty and lies 2 rows and 2 columns away diagonally.
3. Pawns jump forward only (`+2` rows for Red, `-2` rows for Black); Kings can jump both forward and backward.
4. The middle square `(start + dest) / 2` contains an opponent piece.

When a capture runs, the starting square and middle square are cleared (`0`) and the moving piece is placed at the destination.

---

## 3. Core Procedures

### `validate_capture`
- **Inputs:** `$a0 = start`, `$a1 = destination`, `$a2 = player (1 or 3)`
- **Output:** `$v0 = 1` if legal, `0` otherwise.
- **Read-only:** Never modifies `board`.
- **Stack:** 40 bytes (`$s0–$s7, $ra`).

### `apply_capture`
- **Inputs:** `$a0 = start`, `$a1 = destination` (reads global `current_player`)
- **Output:** `$v0 = 1` if executed, `0` if invalid.
- **Behavior:** Calls `validate_capture` first so invalid inputs never touch `board`, then computes the middle square and updates all 3 bytes.
- **Stack:** 32 bytes (`$s0–$s5, $ra`).

### `check_capture`
- **Input:** `$a0 = current square` (reads global `current_player`)
- **Output:** `$v0 = 1` if at least one capture exists from `$a0`, else `0`.
- **Read-only:** Never modifies `board`.
- **Stack:** 40 bytes (`$s0–$s7, $ra`).

### `chain_capture`
- **Input:** `$a0 = current square` (called after the initial capture and its promotion check)
- **Output:** `$v0 = 1` when the chain finishes normally, `0` if the initial arguments are invalid.
- **Loop behavior:**
  1. Calls `check_capture($s0)`. If no jump remains, prints `"No further capture available. Chain complete."` and returns `1`.
  2. Calls `print_board` to refresh the board, then calls `print_capture_moves` to show all valid chain landing squares.
  3. Prompts for the next landing square and calls `apply_capture`. If invalid, asks again without changing the board.
  4. Calls `print_capture_feedback` (e.g., `Captured Red's piece! (14x7)`).
  5. Updates the current square and immediately calls `check_promotion`. If the piece was just promoted to King, prints a promotion notice and loops back to `check_capture` so the new King can jump backwards right away.
- **Stack:** 24 bytes (`$s0–$s3, $ra`).

---

## 4. Helper Procedures (Mandatory Capture, Move Hints & Feedback)

All query helpers below are **strictly read-only** and use the shared offset tables `cap_dr` / `cap_dc` (`(-2,-2), (-2,+2), (+2,-2), (+2,+2)`):

| Procedure | Inputs | Output / Effect | Stack |
|---|---|---|---|
| `has_capture_from` | `$a0 = sq`, `$a1 = player` | `$v0 = 1` if piece at `sq` can capture for `player`, else `0` (does not depend on global `current_player`) | 24 B (`$s0–$s4, $ra`) |
| `has_any_capture` | `$a0 = player` | Scans `1..32`; `$v0 = 1` if any piece of `player` can capture, else `0` | 16 B (`$s0–$s1, $ra`) |
| `print_capture_moves` | `$a0 = sq`, `$a1 = player` | Prints all legal capture landing squares from `sq` in ascending order; returns count in `$v0` | 32 B (`$s0–$s6, $ra`) |
| `print_mandatory_capture_pieces` | `$a0 = player` | Prints all squares (`1..32`) of `player` that have a legal capture; returns count in `$v0` | 16 B (`$s0–$s2, $ra`) |
| `print_capture_feedback` | `$a0 = start`, `$a1 = dest`, `$a2 = player` | Prints `Captured Red's piece! (<start>x<dest>)` or `Captured Black's piece! (<start>x<dest>)` | Leaf (no stack) |

---

## 5. Dependencies & Status

- **Depends on:** `board.asm`, `coordinates.asm`, `promotion.asm`
- **Used by:** `main.asm` and the test harnesses in `tests/`

- [x] `validate_capture`
- [x] `apply_capture`
- [x] `check_capture`
- [x] `chain_capture`
- [x] Mandatory capture, move-hint & notation feedback helpers
- [x] Independent unit tests (`test_member_b`, `test_apply_capture`, `test_check_capture`, `test_chain_capture`, `test_tier1_features`)
- [x] Integration testing with `main.asm`
