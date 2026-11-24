# CO2008 Checkers (MIPS Assembly) — Complete Project Walkthrough

> **Purpose of this document:** A clear, ground-up explanation of everything built in this repository from the first commit to the current state. It walks through each teammate's turn in chronological order, explains **what** the code does, **how** it works at the MIPS instruction and register level, and **why** each architectural decision was made.
>
> This guide is designed both for onboarding/reviewing each other's code and for preparing the final report and presentation.

---

## Table of Contents

1. [Project Big Picture & Team Ownership](#1-project-big-picture--team-ownership)
2. [Core Mental Model: Board, Encoding & Coordinate Math](#2-core-mental-model-board-encoding--coordinate-math)
3. [System Architecture & Module Dependency Map](#3-system-architecture--module-dependency-map)
4. [Chronological Turn-by-Turn History](#4-chronological-turn-by-turn-history)
   - [Turn 1 — Đức (Member A): Repository Bootstrap](#turn-1--đức-member-a-repository-bootstrap)
   - [Turn 2 — Quang (Member B): Architecture, Contracts & Starter Skeleton](#turn-2--quang-member-b-architecture-contracts--starter-skeleton)
   - [Turn 3 — Đức (Member A): Board State, Display & Coordinate Math](#turn-3--đức-member-a-board-state-display--coordinate-math)
   - [Turn 4 — Quang (Member B): Code Review Fix + Full Capture Engine & Winner Check](#turn-4--quang-member-b-code-review-fix--full-capture-engine--winner-check)
   - [Turn 5 — Đức (Member A): Normal Movement Rules & Execution](#turn-5--đức-member-a-normal-movement-rules--execution)
5. [Quick Reference: Procedure Interface & Stack Summary](#5-quick-reference-procedure-interface--stack-summary)
6. [Test Suite Overview](#6-test-suite-overview)
7. [Current Project Status: What's Done, What's Left & Bugs to Fix](#7-current-project-status-whats-done-whats-left--bugs-to-fix)

---

## 1. Project Big Picture & Team Ownership

| Role | Team Member | Student ID | Owned Modules | Core Responsibilities |
|---|---|---|---|---|
| **Member A** | Nguyễn Tuấn Đức | `2550036` | `src/board.asm`, `src/coordinates.asm`, `src/movement.asm`, `src/promotion.asm` | Board memory & display, 1–32 ↔ `(row, col)` math, normal moves (pawn & king), promotion |
| **Member B** | Nguyễn Dương Thiều Quang | `2550206` | `src/capture.asm`, `src/game_control.asm`, `src/main.asm` | Capture validation, capture execution, follow-up & chain captures, winner detection, main game loop |
| **Shared** | Both | — | `plan.md`, `PROJECT_SETUP.md`, `tests/` | Interface contracts, unit tests, integration, report & presentation |

### Why split the project this way?
The game naturally separates into two halves connected by a small, clean interface:
* **Geometry & Basic State (Member A):** Knows *how* the board is stored, *how* to print it, *how* square numbers map to `(row, col)`, and *how* normal 1-step moves and promotions work.
* **Rules Engine & Control Flow (Member B):** Uses Member A's shared `board` array and coordinate conversion functions to implement 2-step jumps, mandatory chain captures, win detection, and the interactive turn loop.

---

## 2. Core Mental Model: Board, Encoding & Coordinate Math

Before reading any `.asm` file, keep these four conventions in mind — **every single file in `src/` depends on them.**

### 2.1. Piece & Player Codes

| Byte Value in `board` | Meaning | Display Char | Owner (`current_player`) | Movement Direction (`d_row`) |
|---:|---|:---:|---|---|
| `0` | Empty playable square | `'0'` | None | — |
| `1` | Red pawn | `'r'` | `1` (Red) | Down only (`+1` move, `+2` capture) |
| `2` | Red king | `'R'` | `1` (Red) | Up or Down (`±1` move, `±2` capture) |
| `3` | Black pawn | `'b'` | `3` (Black — moves first) | Up only (`-1` move, `-2` capture) |
| `4` | Black king | `'B'` | `3` (Black) | Up or Down (`±1` move, `±2` capture) |

* Non-playable light squares are **not stored in memory at all**; they are synthesized when printing the 8×8 grid.

### 2.2. How the 32 Playable Squares Map to the 8×8 Board

Player-facing squares are numbered **`1..32`**, stored in `board[0..31]` using **`index = square - 1`**:

```text
          col 0   col 1   col 2   col 3   col 4   col 5   col 6   col 7
row 0  |   .   |  01 r |   .   |  02 r |   .   |  03 r |   .   |  04 r |  <- Red start / Black promotion row
row 1  |  05 r |   .   |  06 r |   .   |  07 r |   .   |  08 r |   .   |  <- Red start
row 2  |   .   |  09 r |   .   |  10 r |   .   |  11 r |   .   |  12 r |  <- Red start
row 3  |  13 0 |   .   |  14 0 |   .   |  15 0 |   .   |  16 0 |   .   |  <- Empty middle
row 4  |   .   |  17 0 |   .   |  18 0 |   .   |  19 0 |   .   |  20 0 |  <- Empty middle
row 5  |  21 b |   .   |  22 b |   .   |  23 b |   .   |  24 b |   .   |  <- Black start
row 6  |   .   |  25 b |   .   |  26 b |   .   |  27 b |   .   |  28 b |  <- Black start
row 7  |  29 b |   .   |  30 b |   .   |  31 b |   .   |  32 b |   .   |  <- Black start / Red promotion row
```

Notice the mathematical properties that make everything clean:
1. A cell `(row, col)` is a **dark (playable) square** if and only if `(row + col) % 2 == 1`.
2. **Even rows (`0, 2, 4, 6`)** place dark squares on **odd columns** (`1, 3, 5, 7`).
3. **Odd rows (`1, 3, 5, 7`)** place dark squares on **even columns** (`0, 2, 4, 6`).
4. Therefore:
   * `square → (row, col)`:
     * `idx = square - 1`
     * `row = idx / 4` (MIPS: `srl` by 2)
     * `col = 2 * (idx % 4) + 1 - (row % 2)`
   * `(row, col) → square`:
     * `square = 4 * row + (col / 2) + 1` (MIPS: `(row << 2) + (col >> 1) + 1`)

### 2.3. The Golden Rule of State Mutation
* **Validators (`validate_normal_move`, `validate_capture`, `check_capture`, `check_winner`) are strictly read-only.** They must *never* write a single byte to `board`.
* **Appliers (`apply_normal_move`, `apply_capture`, `check_promotion`) mutate `board`.**

---

## 3. System Architecture & Module Dependency Map

```mermaid
flowchart TD
    MAIN["main.asm (Member B)<br/>Game Loop & Input [TODO]"]
    GC["game_control.asm (Member B)<br/>check_winner [DONE]"]
    CAP["capture.asm (Member B)<br/>validate_capture, apply_capture,<br/>check_capture, chain_capture [DONE]"]
    MOV["movement.asm (Member A)<br/>validate_normal_move,<br/>apply_normal_move [DONE]"]
    PRO["promotion.asm (Member A)<br/>check_promotion [TODO STUB]"]
    BRD["board.asm (Member A)<br/>Shared .data, init_board,<br/>print_board [DONE]"]
    CRD["coordinates.asm (Member A)<br/>square_to_coord,<br/>coord_to_square [DONE]"]

    MAIN --> BRD
    MAIN --> MOV
    MAIN --> CAP
    MAIN --> PRO
    MAIN --> GC

    BRD --> CRD
    MOV --> CRD
    MOV --> BRD
    CAP --> CRD
    CAP --> BRD
    CAP --> PRO
    GC --> BRD
```

### Target Turn Lifecycle (as designed in `plan.md`)

```mermaid
flowchart LR
    A["print_board"] --> B["Read start & dest"]
    B --> C{"validate_normal_move?"}
    C -- Yes --> D["apply_normal_move"] --> E["check_promotion"] --> J["check_winner"]
    C -- No --> F{"validate_capture?"}
    F -- No --> B
    F -- Yes --> G["apply_capture"] --> H["check_promotion"] --> I["chain_capture<br/>(loops check_capture →<br/>apply_capture → check_promotion)"] --> J
    J --> K{"game_over?"}
    K -- No --> L["Switch current_player<br/>(3 ↔ 1)"] --> A
    K -- Yes --> M["Announce Winner & Exit"]
```

---

## 4. Chronological Turn-by-Turn History

Below is the exact evolution of the repository from the first commit to the most recent commit.

---

### Turn 1 — Đức (Member A): Repository Bootstrap
* **Date:** Nov 18, 2026
* **Commits:** `82d250c` (*Initial commit*), `3de4d7e` (*Add initial content to README.m*)
* **Files added:** `CA_Assignment_261.pdf`, `README.md`

**What was done & why:**
Đức initialized the repository with the official assignment specification (`CA_Assignment_261.pdf`) and a starter `README.md`, establishing the shared source of truth for the ruleset before planning began.

---

### Turn 2 — Quang (Member B): Architecture, Contracts & Starter Skeleton
* **Date:** Nov 19–20, 2026
* **Commits:** `b425af8`, `edbb7ed` (*Plan for assignment*), `6a7a941`, `a90b68f`, `bdff6d2` (*Initialize Checkers project structure*), `eacb4c5`
* **Files added:** `plan.md`, `PROJECT_SETUP.md`, `tests/test_cases.md`, and starter stubs for all 7 files in `src/`.

**Thought process — Why invest time in scaffolding first?**
In MIPS Assembly, there are no header files, type checkers, or namespaces. If two developers write assembly independently without agreeing on exact register contracts, piece codes, and `.globl` symbol ownership, merging later becomes a nightmare of register corruption and duplicate label errors.

**Key problems solved upfront in this turn:**
1. **Single ownership of global `.data`:** `src/board.asm` was designated the *only* file that defines `board`, `current_player`, `start_square`, `destination`, and `game_over` (all exported with `.globl`). Every other file simply references them with `la`.
2. **MARS 4.5 multi-file constraint:** Although `plan.md` originally illustrated a `modules/` subfolder, `PROJECT_SETUP.md` noted that MARS's *"Assemble all files in directory"* feature does **not** recurse into subdirectories. Placing all `.asm` files flat inside `src/` ensures MARS links the entire program with a single `F3` press.
3. **MIPS Calling Convention Contract:**
   * `$a0–$a3`: arguments in
   * `$v0–$v1`: return values out
   * `$t0–$t9`: caller-saved temporaries (never assume they survive a `jal`)
   * `$s0–$s7`, `$ra`, `$sp`: callee-saved (must be pushed/popped on stack whenever modified or when making nested `jal` calls)
4. **Milestone plan & test checklist:** Defined 6 integration milestones and 13 essential test scenarios in `tests/test_cases.md` so each member could validate their modules independently before integration.

---

### Turn 3 — Đức (Member A): Board State, Display & Coordinate Math
* **Date:** Nov 20, 2026
* **Commits:** `f3b7b89` (*Initialize board, design coordinate for black and red*), merged via `a637625`
* **Files implemented:** `src/board.asm`, `src/coordinates.asm`, `src/board.md`, `src/coordinates.md`, `tests/test_member_a.asm`, plus a temporary hook in `src/main.asm`.

This turn completed **Milestones 1 & 2** — the foundational layer that Member B's capture logic depends on.

#### A. Shared Data in `src/board.asm` (lines 1–16)
```mips
.data
.align 2
.globl board
board: .space 32              # 32 bytes for playable squares 1..32

.globl current_player
current_player: .word 3       # Black (3) moves first per assignment spec
.globl start_square
start_square:   .word 0
.globl destination
destination:    .word 0
.globl game_over
game_over:      .word 0
```
* **Why `.align 2`?** Ensures word-aligned memory (`4`-byte boundary) so `current_player` and subsequent `.word` globals never trigger an unaligned-word exception in MARS (and `32` bytes is already a multiple of 4).

#### B. `init_board` in `src/board.asm` (lines 20–52)
* **What it does:** Initializes `board[0..31]` to standard Checkers starting positions:
  * `i = 0..11` (squares `1..12`) → `1` (Red pawn)
  * `i = 12..19` (squares `13..20`) → `0` (Empty)
  * `i = 20..31` (squares `21..32`) → `3` (Black pawn)
* **Register & Stack Design:** Leaf procedure (no `jal`), uses only `$t0` (base address), `$t1` (index `i`), `$t2` (comparison / piece code), `$t3` (`&board[i]`). No stack frame needed. Uses `sb` (store byte) because each square occupies 1 byte.

#### C. `square_to_coord` in `src/coordinates.asm` (lines 5–26)
* **Signature:** `$a0 = square (1..32)` → `$v0 = row (0..7)`, `$v1 = col (0..7)` (or `-1, -1` if invalid).
* **How the bit-level math works:**
  1. Bounds guard: rejects `$a0 < 1` or `$a0 > 32` (`slti` against `1` and `33`).
  2. `idx = square - 1` (`addi $t0, $a0, -1`)
  3. `row = idx / 4` → `srl $v0, $t0, 2`
  4. `rem = idx % 4` → `andi $t1, $t0, 3`
  5. `row_parity = row % 2` → `andi $t2, $v0, 1`
  6. `col = (rem << 1) + 1 - row_parity` (`sll`, `addi +1`, `subu`)
* **Thought process:** Replacing `div`/`mul` with `srl`/`sll`/`andi` avoids `HI`/`LO` registers, runs in single cycles, and avoids a branch for even vs. odd rows by simply subtracting `row_parity`.

#### D. `coord_to_square` in `src/coordinates.asm` (lines 29–54)
* **Signature:** `$a0 = row`, `$a1 = col` → `$v0 = square (1..32)`, or `-1` if invalid.
* **Checks performed:**
  1. `0 <= row <= 7` (`bltz` + `slti ..., 8`)
  2. `0 <= col <= 7` (`bltz` + `slti ..., 8`)
  3. Playable dark square: `((row + col) & 1) == 1`. If `0`, returns `-1`.
* **Formula:** `(row << 2) + (col >> 1) + 1`.
* **Why returning `-1` matters:** Callers like `check_capture` can generate candidate `(row ± 2, col ± 2)` pairs without doing any bounds math themselves — a single `bltz $v0` rejects both off-board coordinates and light squares automatically.

#### E. `print_board` in `src/board.asm` (lines 56–162)
* **What it does:** Renders the full 8×8 board to the MARS console using syscall `11` (`print_character`).
* **Stack & Register Design:** Non-leaf procedure (calls `coord_to_square`), so it allocates a **16-byte stack frame** saving `$s0` (`row`), `$s1` (`col`), `$s2` (`board` base address), and `$ra`.
* **Walkthrough:**
  1. Outer loop `$s0 = 0..7`, inner loop `$s1 = 0..7`.
  2. Computes `(row + col) & 1`. If `0` (light square), prints inaccessible marker (`'_'`, ASCII `95`) without ever touching `board`.
  3. If `1` (dark square), calls `coord_to_square($s0, $s1)`, defensively checks `1 <= $v0 <= 32` (prints `'?'` if corrupted), loads `board[$v0 - 1]` with `lb`, and branches to map `0 → '0'`, `1 → 'r'`, `2 → 'R'`, `3 → 'b'`, `4 → 'B'`.
  4. Prints a space `' '` after columns `0..6` and `'\n'` after column `7`.

#### F. `tests/test_member_a.asm`
Verifies `init_board` + `print_board` visually, then exhaustively loops `s = 1..32` checking that `coord_to_square(square_to_coord(s)) == s` (the **round-trip bijection test**).

---

### Turn 4 — Quang (Member B): Code Review Fix + Full Capture Engine & Winner Check
* **Date:** Nov 21, 2026
* **Commits:**
  * `13958c7` (*Fix board display and Member A test harness*)
  * `f03512f` (*Complete capture and game control modules*)
* **Files changed/added:** `src/board.asm`, `tests/test_member_a.asm`, `src/capture.asm` (992 lines), `src/capture.md`, `src/game_control.asm` (138 lines), `plan.md`, and 5 test harnesses in `tests/`.

#### Part 4A — Peer Review & Cleanup (`13958c7`)
When Quang pulled Đức's code to start building capture logic on top of it, he caught and fixed three practical issues:
1. Removed duplicate `.data` declarations (`board`, `current_player`, etc.) in `tests/test_member_a.asm` because `.include "../src/board.asm"` already defines them.
2. Fixed `.include "../modules/..."` paths in `tests/test_member_a.asm` to `"../src/..."`.
3. Changed `print_inaccessible` in `src/board.asm` from `'_'` (`95`) to `'-'` (`45`) to match the assignment PDF's illustrated output *(later reverted by Turn 5 — see Section 7)*.

#### Part 4B — The Capture Module (`src/capture.asm`)
This module implements all four capture procedures in a layered, composable design:

```text
chain_capture  ──►  check_capture  ──►  validate_capture  ──►  square_to_coord / coord_to_square
      │                                        ▲
      ├──────────►  apply_capture  ────────────┘
      └──────────►  check_promotion (Member A)
```

##### 1. `validate_capture` (`src/capture.asm`, lines 20–326)
* **Signature:** `$a0 = start`, `$a1 = destination`, `$a2 = current_player` → `$v0 = 1` (valid) or `0` (invalid). **Strictly read-only.**
* **Stack frame (40 bytes):** Saves `$s0–$s7` and `$ra`:
  * `$s0` = start square, `$s1` = dest square, `$s2` = current player, `$s3` = piece at start
  * `$s4, $s5` = `(r1, c1)` start coordinates
  * `$s6, $s7` = `(r2, c2)` destination coordinates
* **The 6-Stage Validation Pipeline:**
  1. **Range check:** `start ∈ 1..32` and `dest ∈ 1..32`.
  2. **Player & Ownership check:** `current_player` must be `1` or `3`. Loads `board[start - 1]` with `lbu` and confirms it belongs to that player (`1, 2` for Red; `3, 4` for Black).
  3. **Empty landing square:** Loads `board[dest - 1]` and requires `== 0`.
  4. **2-Square Diagonal Geometry:** Calls `square_to_coord(start)` and `square_to_coord(dest)`. Computes `d_row = r2 - r1`, `d_col = c2 - c1`. Requires `d_row ∈ {+2, -2}` and `d_col ∈ {+2, -2}`.
  5. **Direction Rule (Pawn vs. King):**
     * Red pawn (`1`) → requires `d_row == +2` (downward)
     * Black pawn (`3`) → requires `d_row == -2` (upward)
     * Kings (`2, 4`) → skip check (both directions allowed)
  6. **Midpoint & Opponent Check:**
     * Computes `mid_row = (r1 + r2) >> 1` and `mid_col = (c1 + c2) >> 1`.
     * Calls `coord_to_square(mid_row, mid_col)` (rejects if `< 0`).
     * Loads `mid_piece = board[mid_sq - 1]`. Rejects if `0` (empty) or friendly; accepts **only** if opponent (`3` or `4` when Red jumps; `1` or `2` when Black jumps).
* **Thought process:** Computing the jumped square in 2D coordinate space via midpoint averaging `(r1 + r2)/2, (c1 + c2)/2` avoids all the error-prone `+4/+5/-4/-3` offset quirks of 1–32 Checkers numbering.

##### 2. `apply_capture` (`src/capture.asm`, lines 352–507)
* **Signature:** `$a0 = start`, `$a1 = destination` (reads global `current_player`) → `$v0 = 1` (success) or `0` (failed).
* **Stack frame (32 bytes):** Saves `$s0–$s5` and `$ra`.
* **How it works:**
  1. **Self-validates first:** Loads `current_player` and calls `validate_capture($a0, $a1, current_player)`. If `0`, returns `0` immediately — guaranteeing `board` is untouched on any invalid input.
  2. Reads moving piece `board[start - 1]` into `$s2`.
  3. Recomputes the middle square via `square_to_coord` + midpoint average + `coord_to_square`, saving it in `$s5`.
  4. Performs **3 atomic byte writes**:
     * `sb $zero` to `board[start - 1]` (vacate start)
     * `sb $zero` to `board[mid - 1]` (remove captured opponent)
     * `sb $s2` to `board[dest - 1]` (land moving piece)
  5. Returns `$v0 = 1`.

##### 3. `check_capture` (`src/capture.asm`, lines 530–792)
* **Signature:** `$a0 = current_square` (reads global `current_player`) → `$v0 = 1` if at least one legal capture exists from this square, else `0`. **Strictly read-only.**
* **Stack frame (40 bytes):** Saves `$s0–$s7` and `$ra`:
  * `$s0` = current square, `$s1` = `current_player`, `$s2` = piece (reused for candidate square)
  * `$s3, $s4` = `(row, col)` of current square
  * `$s5` = current `row_dir` (`+2` or `-2`)
  * `$s6` = current `col_dir` (`-2`, then `+2`)
  * `$s7` = number of row directions to test (`1` for pawns, `2` for kings)
* **How it works:**
  1. Validates `current_square ∈ 1..32` and loads `piece = board[current_square - 1]`.
  2. Sets search directions by piece type:
     * Red pawn → `row_dir = +2`, count `1` (tests 2 diagonals: down-left, down-right)
     * Black pawn → `row_dir = -2`, count `1` (tests 2 diagonals: up-left, up-right)
     * Any King → `row_dir = -2`, count `2` (tests all 4 diagonals: up-left, up-right, then switches `row_dir = +2` for down-left, down-right)
  3. For each candidate `(row + row_dir, col + col_dir)`:
     * Calls `coord_to_square`. If `< 0` (off board), skips to next direction.
     * Calls `validate_capture(current_sq, candidate_sq, current_player)`.
     * **Short-circuits** immediately with `$v0 = 1` as soon as one legal capture is found.
* **Thought process:** Reusing `validate_capture` as the oracle guarantees that `check_capture` and `validate_capture` can never disagree on legality.

##### 4. `chain_capture` (`src/capture.asm`, lines 824–992)
* **Signature:** `$a0 = current_square` (called *after* the initial capture and its promotion check) → `$v0 = 1` (chain completed) or `0` (invalid initial state).
* **Stack frame (16 bytes):** Saves `$s0` (`current_sq`), `$s1` (`current_player`), `$s2` (user-entered destination), `$ra`.
* **Interactive Loop:**
  1. Validates initial `current_sq ∈ 1..32` and `current_player ∈ {1, 3}`.
  2. Calls `check_capture($s0)`. If `0`, prints `"No further capture available. Chain complete.\n"` and returns `1`.
  3. Prompts `"Chaining possible. Enter landing square: "` (`syscall 4`) and reads an integer (`syscall 5`) into `$s2`.
  4. Calls `apply_capture($s0, $s2)`.
     * If `0` (bad input / illegal jump) → prints `"Not a valid capture! Try another landing square.\n"` and loops back to step 3. Neither `board` nor `current_player` changes.
  5. Moves `$s0 = $s2` (the piece is now at the new square).
  6. **Calls `check_promotion($s0)` immediately** — before looping back to step 2 (`check_capture`).
* **Why step 6 is crucial:** Per the Checkers assignment rules, if a pawn lands on its promotion row mid-chain, it becomes a King *immediately* and can continue capturing **backwards** on the very next hop of the same turn. Calling `check_promotion` before `check_capture` makes that work automatically.

#### Part 4C — Winner Detection (`src/game_control.asm`)
##### `check_winner` (`src/game_control.asm`, lines 33–138)
* **Signature:** `$a0 = player_to_check` (`1` = Red, `3` = Black) →
  * `$v0 = 1`: player has **0 remaining pieces** (eliminated — the other player wins!)
  * `$v0 = 0`: player still has at least one piece
  * `$v0 = -1`: invalid player argument
* **How it works:** Leaf procedure (no stack). Sets `$t5, $t6` to the player's pawn & king codes (`1, 2` for Red; `3, 4` for Black), walks `board[0..31]` with `lbu`, returns `0` immediately on the first match, or `1` if all 32 bytes contain none of that player's pieces.

---

### Turn 5 — Đức (Member A): Normal Movement Rules & Execution
* **Date:** Nov 22, 2026 *(latest commit)*
* **Commit:** `4ecea24` (*update board and generate movement rules and step.*)
* **Files changed/added:** `src/movement.asm`, `src/movement.md`, `src/board.asm`, `src/main.asm`.

This turn completed **Milestone 3** and King movement from **Milestone 4**.

#### 1. `validate_normal_move` (`src/movement.asm`, lines 3–118)
* **Signature:** `$a0 = start`, `$a1 = destination`, `$a2 = current_player` → `$v0 = 1` (valid) or `0` (invalid). **Strictly read-only.**
* **Stack frame (24 bytes):** Saves `$s0–$s4` and `$ra`:
  * `$s0` = start square, `$s1` = dest square, `$s2` = piece at start
  * `$s3, $s4` = `(r1, c1)` start coordinates
* **The 6-Stage Validation Pipeline:**
  1. **Range check:** `start ∈ 1..32` and `dest ∈ 1..32`.
  2. **Ownership check:** Loads `board[start - 1]` into `$s2`; verifies `current_player == 1` owns `1` or `2`, and `current_player == 3` owns `3` or `4`.
  3. **Empty destination:** Verifies `board[dest - 1] == 0`.
  4. **Coordinate conversion:** Calls `square_to_coord(start)` → `($s3, $s4)` and `square_to_coord(dest)` → `($v0, $v1)`. Computes `d_row = r2 - r1` (`$t0`) and `d_col = c2 - c1` (`$t1`).
  5. **Horizontal distance:** Requires `d_col == +1` or `-1` (one column diagonally).
  6. **Vertical direction (Pawn vs. King):**
     * Red pawn (`1`) → requires `d_row == +1` (down)
     * Black pawn (`3`) → requires `d_row == -1` (up)
     * Kings (`2` or `4`) → requires `d_row == +1` or `-1` (both directions)
* **Thought process:** Follows the exact same defensive pattern and register discipline as `validate_capture`, making the two validators symmetric and easy to maintain.

#### 2. `apply_normal_move` (`src/movement.asm`, lines 121–145)
* **Signature:** `$a0 = start`, `$a1 = destination` (no return value).
* **How it works:** Leaf procedure (no stack, uses `$t0–$t3`). Guards `start, dest ∈ 1..32`, reads `piece = board[start - 1]`, writes `piece` to `board[dest - 1]`, and writes `$zero` to `board[start - 1]`.

---

## 5. Quick Reference: Procedure Interface & Stack Summary

| Procedure | File | Owner | Inputs | Outputs | Mutates `board`? | Stack Frame | Status |
|---|---|---|---|---|:---:|---|:---:|
| `init_board` | `src/board.asm` | A | None | None | Yes (all 32B) | None (leaf) | Done |
| `print_board` | `src/board.asm` | A | None | Console output | No | 16 B (`$s0–$s2, $ra`) | Done |
| `square_to_coord` | `src/coordinates.asm` | A | `$a0 = sq (1..32)` | `$v0 = row`, `$v1 = col` (or `-1,-1`) | No | None (leaf) | Done |
| `coord_to_square` | `src/coordinates.asm` | A | `$a0 = row`, `$a1 = col` | `$v0 = sq (1..32)` or `-1` | No | None (leaf) | Done |
| `validate_normal_move` | `src/movement.asm` | A | `$a0 = start`, `$a1 = dest`, `$a2 = player` | `$v0 = 1` (valid) / `0` (invalid) | No | 24 B (`$s0–$s4, $ra`) | Done |
| `apply_normal_move` | `src/movement.asm` | A | `$a0 = start`, `$a1 = dest` | None | Yes (2 B) | None (leaf) | Done |
| `check_promotion` | `src/promotion.asm` | A | `$a0 = dest_sq` | None | Yes (0–1 B) | TBD | **TODO** |
| `validate_capture` | `src/capture.asm` | B | `$a0 = start`, `$a1 = dest`, `$a2 = player` | `$v0 = 1` (valid) / `0` (invalid) | No | 40 B (`$s0–$s7, $ra`) | Done |
| `apply_capture` | `src/capture.asm` | B | `$a0 = start`, `$a1 = dest` *(reads `current_player`)* | `$v0 = 1` (ok) / `0` (fail) | Yes (3 B) | 32 B (`$s0–$s5, $ra`) | Done |
| `check_capture` | `src/capture.asm` | B | `$a0 = sq` *(reads `current_player`)* | `$v0 = 1` (exists) / `0` (none) | No | 40 B (`$s0–$s7, $ra`) | Done |
| `chain_capture` | `src/capture.asm` | B | `$a0 = sq` *(reads `current_player`)* | `$v0 = 1` (done) / `0` (bad state) | Yes (loop) | 16 B (`$s0–$s2, $ra`) | Done |
| `check_winner` | `src/game_control.asm` | B | `$a0 = player (1 or 3)` | `$v0 = 1` (eliminated) / `0` (alive) / `-1` (err) | No | None (leaf) | Done |
| `main` | `src/main.asm` | B | None | Runs full game | Via calls | TBD | **TODO** |

---

## 6. Test Suite Overview

All tests live in `tests/` and can be assembled individually in MARS:

| Test File | Author | What It Tests | Key Cases Covered |
|---|---|---|---|
| `tests/test_member_a.asm` | A (fixed by B) | `init_board`, `print_board`, `square_to_coord`, `coord_to_square`, normal move | Initial 8×8 print; all 32 squares round-trip bijection (`1..32`); Black normal move `21 → 17` |
| `tests/test_member_b.asm` | B | `validate_capture` | `C1–C10`: Black/Red forward capture, board unchanged after validation, empty middle, friendly middle, occupied dest, backward pawn (fail), backward king (pass), wrong player, bad distance |
| `tests/test_apply_capture.asm` | B | `apply_capture` | Valid jump updates exactly 3 squares (`21 → 14` over `17`); invalid jump leaves entire board untouched |
| `tests/test_check_capture.asm` | B | `check_capture` | `CC1–CC5`: Black pawn forward capture, no capture, backward pawn blocked, backward king allowed, Red pawn forward capture |
| `tests/test_chain_capture.asm` | B | `chain_capture` | Interactive follow-up capture (`14 → 7` over `10`), verifies board bytes after chain finishes |
| `tests/test_check_winner.asm` | B | `check_winner` | `W1–W5`: Red pawn alive, Black king alive, Red eliminated, Black eliminated, empty board |

---

## 7. Current Project Status: What's Done, What's Left & Bugs to Fix

### 7.1. Remaining Work Before the Game Is Playable

1. **Member A — Implement `check_promotion` in `src/promotion.asm`:**
   * Input: `$a0 = destination square (1..32)`.
   * Validate `$a0 ∈ 1..32`. Load `piece = board[$a0 - 1]`.
   * If `piece == 1` (Red pawn) and `$a0 >= 29` (squares `29..32`, row `7`) → store `2` (Red king).
   * If `piece == 3` (Black pawn) and `$a0 <= 4` (squares `1..4`, row `0`) → store `4` (Black king).
   * Otherwise leave `board[$a0 - 1]` unchanged. (Can be a tiny leaf procedure with no stack!)
2. **Member B — Implement the Main Game Loop in `src/main.asm` & helpers in `src/game_control.asm`:**
   * Call `init_board`, set `current_player = 3`, `game_over = 0`.
   * Loop while `game_over == 0`:
     1. `print_board` and print whose turn it is (Black or Red).
     2. Read `start_square` and `destination` from the user.
     3. Try `validate_normal_move(start, dest, current_player)`:
        * If valid (`1`): `apply_normal_move(start, dest)` → `check_promotion(dest)`.
     4. Else try `validate_capture(start, dest, current_player)`:
        * If valid (`1`): `apply_capture(start, dest)` → `check_promotion(dest)` → `chain_capture(dest)`.
        * If invalid (`0`): print invalid move message and re-prompt **without** switching turns.
     5. Determine the opponent (`opponent = 4 - current_player`, since `4 - 3 = 1` and `4 - 1 = 3`) and call `check_winner(opponent)`.
        * If `$v0 == 1`: set `game_over = 1`, print final board & winner announcement, and exit.
        * Otherwise: set `current_player = opponent` and continue the loop.
3. **End-to-End Integration Testing (Both):**
   * Run all 13 scenarios from `tests/test_cases.md` together, especially **Scenario 11 & 12** (mid-chain pawn promotion immediately followed by a backward king capture) and a full game to win condition.

### 7.2. Small Discrepancies Found in the Current Codebase (Fix Before Integration)

| # | File & Line | Issue | Recommended Fix |
|---:|---|---|---|
| 1 | `src/main.asm:20` | Calls `jal run_member_a_tests`, which is **not defined** anywhere in `src/` (or `tests/`). Assembling `src/` in MARS right now will fail with an unresolved symbol error. | Replace with the real game loop (or temporarily restore `init_board` + `print_board` until the game loop is written). |
| 2 | `src/board.asm:112` | `print_inaccessible` was changed from `'_'` (`95`) to `'-'` (`45`) by Quang in commit `13958c7` to match the PDF, then accidentally reverted back to `'_'` (`95`) by Đức in commit `4ecea24`. | Agree on `'-'` vs `'_'` against `CA_Assignment_261.pdf` and keep it consistent. |
| 3 | `src/capture.asm:516` & `src/capture.md:113` | Header comments say `check_capture` takes `$a1 = current player`, while the actual assembly (`src/capture.asm:552-553`) ignores `$a1` and loads global `current_player` — which matches `plan.md` and `chain_capture`. | Update the comments in `src/capture.asm` and `src/capture.md` to list `$a0` only (and note global `current_player`). |
| 4 | `src/capture.md:208-211` & `plan.md:26-33` | Status checkboxes are slightly stale (`capture.md` still shows unchecked boxes even though all 4 functions are done; `plan.md` still shows Member A's completed functions unchecked). | Update checkboxes after final integration so documentation matches code state. |
| 5 | `src/movement.asm:141-142` | In `apply_normal_move`, writing `dest` and then clearing `start` would erase a piece if ever called directly with `start == dest` (safe whenever `validate_normal_move` runs first, since `dest` must be empty). | Optional guard `beq $a0, $a1, anm_done`, or document that callers must validate first. |
