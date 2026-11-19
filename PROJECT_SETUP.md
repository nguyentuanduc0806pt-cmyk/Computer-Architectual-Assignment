# CO2008 Checkers — Project Setup

This starter layout is for the two-person MIPS Checkers assignment.

## Folder layout

```text
Computer-Architectual-Assignment/
├── CA_Assignment_261.pdf
├── README.md
├── plan.md
├── PROJECT_SETUP.md
├── src/
│   ├── main.asm
│   ├── board.asm
│   ├── coordinates.asm
│   ├── movement.asm
│   ├── promotion.asm
│   ├── capture.asm
│   └── game_control.asm
└── tests/
    └── test_cases.md
```

**Important for MARS 4.5:** Keep every project `.asm` file directly inside `src/`. MARS's multi-file assembly option assembles `.asm`/`.s` files in the current source file's directory; it does not recursively collect files from nested module folders.

## Initialize in MARS 4.5

1. Open `src/main.asm` in MARS.
2. Open **Settings** and enable **Assemble all files in directory**.
3. Enable **Initialize Program Counter to global 'main' if defined**.
4. Keep all `.asm` files in `src/`.
5. Press **F3 (Assemble)**. The starter program should print a setup message and exit.

The other `.asm` files currently contain clearly marked TODO stubs, not completed game logic. Replace them as each member implements their assigned procedures.

## Module ownership

- **Member A:** `board.asm`, `coordinates.asm`, `movement.asm`, `promotion.asm`
- **Member B:** `main.asm`, `capture.asm`, `game_control.asm`
- **Both:** `tests/test_cases.md`, integration, review, end-to-end testing

## Shared state and piece encodings

`board.asm` declares the shared 32-byte `board` array and game-state variables:

| Value | Meaning |
|---:|---|
| 0 | Empty playable square |
| 1 | Red pawn |
| 2 | Red king |
| 3 | Black pawn |
| 4 | Black king |

Player-facing squares are numbered 1–32; array index = square number − 1. `current_player` starts at 3 because the assignment says Black moves first. The `board` array is only reserved here; Member A must implement `init_board` to place the 12 red and 12 black pawns.

Cross-file data labels and procedures that another `.asm` file needs to access must be declared with `.globl` in the file where they are defined. Do not define the same global label in two files.

## Two interface decisions before full integration

The work plan lists `chain_capture` and `check_winner`, but does not specify their return-value contracts. Before implementing calls to them, agree together on the exact values they return and document those values in `plan.md` or the relevant source comments.
