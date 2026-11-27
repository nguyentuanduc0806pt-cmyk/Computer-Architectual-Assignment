# CO2008 Checkers (MARS MIPS Assembly)

**Team members:**
- **Nguyễn Tuấn Đức** – `2550036` (Member A: board, coordinates, normal movement, promotion)
- **Nguyễn Dương Thiều Quang** – `2550206` (Member B: captures, chain captures, game control, main loop)

A playable two-player Checkers game written in MIPS Assembly for **MARS 4.5**, supporting both **American / English Checkers (8×8)** and **International Checkers (10×10)**.

---

## Features

**Two Full Checkers Rulesets**
- **American / English Checkers (`8×8`, 32 dark squares, 12 pieces/side)** — follows [american_checkers.pdf](./american_checkers.pdf):
  - Pawns move and capture diagonally forward only; Kings move 1 square and capture 2 squares diagonally forward or backward.
  - Mandatory capture (Official mode) or optional initial capture (Casual mode), with mandatory multi-jump chains.
  - Pawn promotion on the king-row **ends the turn immediately**.
- **International Checkers (`10×10`, 50 dark squares, 20 pieces/side)** — follows [ItsYourTurn International Checkers rules](https://www.itsyourturn.com/t_helptopic2130.html#helpitem1324):
  - Pawns move 1 square diagonally forward and **capture both forward and backward**.
  - **Flying Kings** slide any unobstructed diagonal distance and capture opponent pieces at any distance, landing on any empty square beyond along that diagonal.
  - **Maximum Capture Rule:** if multiple capture sequences exist, the player must choose a piece and path that captures the maximum number of opponent pieces.
  - Captured pieces remain marked (`x`) on the board until the entire multi-jump sequence completes (cannot jump over the same piece twice).
  - Pawns promote to King only if they **end their turn** on the king-row.

**Board UI, Perspective & Multi-Jump Hints**
- **Automatic 180° Board Rotation:** `print_board` automatically flips the board, square-number reference map (`1–32` or `1–50`), and row/column labels 180° on Red's turn so the active player always plays from the bottom upward.
- **All Legal Captures & Multi-Jump Path Previews:** Selecting a capturing piece displays **all** legal 1st-hop landing squares (including backward pawn jumps and all Flying King landing squares) *plus* complete multi-jump chain previews (e.g. `21x14x5`, `21x14x7`), stepping through each hop with live board updates.
- **Side selection & feedback:** Player 1 picks Black or Red at startup (Black still moves first), with standard notation feedback (`21-17`, `17x10`), promotion notices, live piece counts, and both elimination and trap-win detection.

---

## Project Layout

```text
├── src/
│   ├── main.asm           # Entry point, turn loop, ruleset promotion timing, trap-win helper
│   ├── board.asm          # Shared globals (50-byte board & mask), 8x8/10x10 init, rotated print_board
│   ├── coordinates.asm    # Dynamic 8x8 & 10x10 square_to_coord / coord_to_square (1..32 or 1..50)
│   ├── movement.asm       # Normal moves, International Flying King sliding & move hints
│   ├── promotion.asm      # Dynamic 8x8 (1..4 / 29..32) & 10x10 (1..5 / 46..50) promotion
│   ├── capture.asm        # Captures, Flying King jumps, max-capture DFS, multi-jump path previews
│   └── game_control.asm   # Side & ruleset selection (American/International/Casual), banners, I/O
├── tests/                 # 8 standalone MARS test harnesses + test_cases.md
├── plan.md                # Team plan, conventions, and checklist
├── PROJECT_SETUP.md       # MARS setup and module contracts
└── PROJECT_WALKTHROUGH.md # Full architecture & commit-by-commit walkthrough
```

---

## How to Run the Game

### In MARS 4.5 GUI
1. Open [src/main.asm](./src/main.asm).
2. In **Settings**, turn on:
   - **Assemble all files in directory**
   - **Initialize Program Counter to global 'main' if defined**
3. Press **F3** (Assemble) and **F5** (Run).

### From the Terminal (PowerShell)
```powershell
java -jar "path\to\Mars4_5.jar" p sm src\main.asm
```
*(In VS Code, you can also run **Tasks: Run Task → Run Checkers (MARS)** from `.vscode/tasks.json`.)*

---

## How to Run the Tests

Each test file in `tests/` `.include`s the exact `src/` modules it needs and defines its own `main`. Run them **one at a time without** the `p` (assemble-all) flag:

```powershell
$MARS = "path\to\Mars4_5.jar"

java -jar $MARS nc sm tests\test_member_a.asm
java -jar $MARS nc sm tests\test_member_b.asm
java -jar $MARS nc sm tests\test_apply_capture.asm
java -jar $MARS nc sm tests\test_check_capture.asm
java -jar $MARS nc sm tests\test_check_winner.asm
java -jar $MARS nc sm tests\test_tier1_features.asm
java -jar $MARS nc sm tests\test_new_features.asm

# Interactive chain-capture test (expects landing square 7)
"7" | java -jar $MARS nc sm tests\test_chain_capture.asm
```

In the MARS GUI, open one test file, **uncheck** *Assemble all files in directory*, keep *Initialize Program Counter to global 'main' if defined* checked, and press **F3 → F5**.
