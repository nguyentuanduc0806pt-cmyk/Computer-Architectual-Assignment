# CO2008 Checkers — Project Setup

Reference guide for how the project is laid out, how MARS 4.5 builds it, and what shared data/contracts the modules rely on.

## Folder layout

```text
Computer-Architectual-Assignment/
├── CA_Assignment_261.pdf
├── README.md
├── plan.md
├── PROJECT_SETUP.md
├── PROJECT_WALKTHROUGH.md
├── src/
│   ├── main.asm
│   ├── board.asm
│   ├── coordinates.asm
│   ├── movement.asm
│   ├── promotion.asm
│   ├── capture.asm
│   └── game_control.asm
└── tests/
    ├── test_cases.md
    ├── test_member_a.asm
    ├── test_member_b.asm
    ├── test_apply_capture.asm
    ├── test_check_capture.asm
    ├── test_check_winner.asm
    ├── test_chain_capture.asm
    └── test_tier1_features.asm
```

**Important for MARS 4.5:** Keep every project `.asm` file directly inside `src/`. MARS's *"Assemble all files in directory"* option only scans the current file's folder and does not look inside subdirectories.

## Running in MARS 4.5

1. Open `src/main.asm` in MARS.
2. Under **Settings**, enable **Assemble all files in directory**.
3. Enable **Initialize Program Counter to global 'main' if defined**.
4. Press **F3 (Assemble)**, then **F5 (Run)**.

When running an individual test file inside `tests/`, **disable** *Assemble all files in directory* (each test defines its own `main` and `.include`s the modules it needs from `../src/`).

## Module ownership

- **Member A:** `board.asm`, `coordinates.asm`, `movement.asm`, `promotion.asm`
- **Member B:** `main.asm`, `capture.asm`, `game_control.asm`
- **Shared:** `tests/`, integration, review, documentation

## Shared globals and piece encoding

`src/board.asm` is the single owner of all shared global data (exported with `.globl`):

| Label | Type | Default | Meaning |
|---|---|---:|---|
| `board` | `.space 32` | — | 32 playable dark squares (`index = square - 1`) |
| `current_player` | `.word` | `3` | Active side (`3` = Black moves first, `1` = Red) |
| `start_square` | `.word` | `0` | Last starting square entered by the player |
| `destination` | `.word` | `0` | Last destination square entered by the player |
| `game_over` | `.word` | `0` | `0` while playing, `1` once a winner is announced |
| `player1_color` | `.word` | `3` | Color picked by Player 1 (`3` = Black, `1` = Red) |
| `mandatory_capture` | `.word` | `1` | `1` = Official English rules (mandatory capture), `0` = Casual |

Piece byte values stored in `board`:

| Value | Meaning | Display |
|---:|---|:---:|
| `0` | Empty playable square | `0` |
| `1` | Red pawn | `r` |
| `2` | Red king | `R` |
| `3` | Black pawn | `b` |
| `4` | Black king | `B` |

Any cross-file label or procedure must be declared `.globl` in the file that defines it, and never duplicated in another file.

## Finalized interface contracts

The two return-value contracts left open in the starter plan are finalized as follows:
- **`chain_capture($a0 = current_square)`** returns `$v0 = 1` when the chain finishes cleanly, or `$v0 = 0` if the starting square or `current_player` is invalid.
- **`check_winner($a0 = player)`** returns `$v0 = 1` if `player` has 0 remaining pieces, `$v0 = 0` if they still have at least one piece, and `$v0 = -1` for an invalid player code.
- Trapped-opponent detection is handled by **`player_has_any_legal_move($a0 = player)`** in `src/main.asm` (returns `$v0 = 1` if the player has at least one normal move or capture, `0` if trapped), keeping `game_control.asm` independent of `movement.asm` and `capture.asm` so `test_check_winner.asm` continues to run standalone.
