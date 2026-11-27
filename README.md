# CO2008 Checkers (MARS MIPS Assembly)

**Team members:**
- **Nguyễn Tuấn Đức** – `2550036` (Member A: board, coordinates, normal movement, promotion)
- **Nguyễn Dương Thiều Quang** – `2550206` (Member B: captures, chain captures, game control, main loop)

A playable two-player English Checkers game written in MIPS Assembly for **MARS 4.5**.

---

## Features

**Core rules**
- Compact 32-byte `board` array representing the 32 playable dark squares (`1–32`), expanded to an 8×8 grid when printed.
- Diagonal movement for Red (`r`) and Black (`b`) pawns, with Black moving first.
- Single captures and mandatory multi-jump chain captures.
- Immediate pawn promotion to King (`R` / `B`) on reaching the opposite back row — including mid-chain so a newly crowned King can keep jumping backwards on the same turn.
- Full input validation (out-of-range squares, empty squares, opponent pieces, blocked pieces, illegal destinations) without ever mutating the board on an invalid move.

**Extra QoL & ruleset improvements**
- **Upgraded board display:** Boxed 8×8 ASCII grid with row/column labels, a side-by-side `1–32` square number map, symbol legend, and live remaining piece counts.
- **Side selection:** Player 1 picks Black or Red at startup (Player 2 gets the other color; Black still moves first), and turn/win banners show both Player 1/2 and color.
- **Official vs. Casual ruleset:** Choose at startup whether initial captures are mandatory (Official English Checkers) or optional (Casual mode). When mandatory capture is on, the game lists every piece that can capture and blocks non-capturing moves.
- **Selected-piece legal move hints:** After entering a starting square, the game prints the piece type and all legal move/capture destinations (and lets you enter `0` to pick a different piece). Chain captures also list valid landing squares before each hop.
- **Standard Checkers move feedback:** Prints moves in standard notation (`Move played: 21-17`, `Captured Red's piece! (17x10)`) and announces promotions right when they happen.
- **Trap-win detection:** Detects both win conditions — capturing all opponent pieces *and* trapping the opponent with zero legal moves left.

---

## Project Layout

```text
├── src/
│   ├── main.asm           # Entry point, turn loop, trap-win helper
│   ├── board.asm          # Shared globals, init_board, enhanced print_board
│   ├── coordinates.asm    # square_to_coord & coord_to_square (1..32 <-> row, col)
│   ├── movement.asm       # Normal move validation, execution & move-hint queries
│   ├── promotion.asm      # Immediate pawn-to-king promotion
│   ├── capture.asm        # Capture validation/execution, chain capture, mandatory scan
│   └── game_control.asm   # Side/mode selection, turn/win banners, input & feedback helpers
├── tests/                 # 7 standalone MARS test harnesses + test_cases.md
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

Each test file in `tests/` `.include`s the exact `src/` modules it needs and defines its own `main`. Because of that, run them **one at a time without** the `p` (assemble-all) flag:

```powershell
$MARS = "path\to\Mars4_5.jar"

java -jar $MARS nc sm tests\test_member_a.asm
java -jar $MARS nc sm tests\test_member_b.asm
java -jar $MARS nc sm tests\test_apply_capture.asm
java -jar $MARS nc sm tests\test_check_capture.asm
java -jar $MARS nc sm tests\test_check_winner.asm
java -jar $MARS nc sm tests\test_tier1_features.asm

# Interactive chain-capture test (expects landing square 7)
"7" | java -jar $MARS nc sm tests\test_chain_capture.asm
```

In the MARS GUI, just open one test file, **uncheck** *Assemble all files in directory*, keep *Initialize Program Counter to global 'main' if defined* checked, and press **F3 → F5**.
