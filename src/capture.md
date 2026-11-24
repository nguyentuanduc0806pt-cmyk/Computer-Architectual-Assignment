
# Capture Module — CO2008 Checkers

**Owner:** Member B

## 1. Module Overview

This module implements the capturing mechanics of the
English Checkers game using MIPS Assembly.

Responsibilities:
- Validate capture movements.
- Execute valid captures.
- Detect available consecutive captures.
- Handle chain captures.

Source file: `capture.asm`

## 2. Board Representation

The module uses the shared 32-byte board array
defined in `board.asm`.

| Value | Piece |
|---|---|
| 0 | Empty |
| 1 | Red pawn |
| 2 | Red king |
| 3 | Black pawn |
| 4 | Black king |

Square numbers range from 1 to 32.

Array index = Square number - 1.

Coordinates use zero-based indexing.

## 3. Capture Rules

A capture requires:
1. The moving piece belongs to the current player.
2. The opponent occupies the intermediate square.
3. The landing square is empty.
4. The movement covers exactly two squares diagonally.
5. Pawns capture forwards only.
6. Kings capture forwards and backwards.

After a successful capture:
- The starting square becomes empty.
- The opponent's piece is removed.
- The moving piece occupies the landing square.

## 4. Procedure Specifications

### 4.1 validate_capture

Purpose:
Determine whether a proposed capture is legal.

Inputs:
- $a0: Starting square
- $a1: Destination square
- $a2: Current player (1 = Red, 3 = Black)

Output:
- $v0 = 1: Valid capture
- $v0 = 0: Invalid capture

Important:
This procedure must not modify the board.

### 4.2 apply_capture

Purpose:
Execute a previously proposed capture.

Inputs:
- $a0 = Starting square
- $a1 = Destination square

Uses:
- current_player (shared variable)

Output:
- $v0 = 1: Capture successfully executed
- $v0 = 0: Capture failed

Algorithm:
1. Validate the proposed capture.
2. Retrieve the moving piece.
3. Calculate the intermediate square.
4. Calculate the three board addresses.
5. Clear the starting square.
6. Remove the opponent from the intermediate square.
7. Place the moving piece at the destination.

Board modification:
This procedure modifies exactly three playable squares
when a capture succeeds.

Testing:
- Valid capture updates all three squares.
- Invalid capture leaves the board unchanged.

### 4.3 check_capture

Purpose:
Determine whether a piece has at least one legal capture
available from its current position.

Inputs:
- $a0: Current square

Uses:
- current_player (shared variable: 1 = Red, 3 = Black)

Output:
- $v0 = 1: At least one legal capture exists
- $v0 = 0: No legal capture exists

Algorithm:
1. Retrieve the current piece from the board.
2. Determine permitted capture directions.
3. Convert the current square into coordinates.
4. Generate possible landing coordinates.
5. Reject coordinates outside the playable board.
6. Convert candidate coordinates into square numbers.
7. Call validate_capture for each candidate.
8. Return 1 as soon as a legal capture is found.
9. Return 0 if no candidate is legal.

Board modification:
This procedure does not modify the board.

Dependencies:
- square_to_coord
- coord_to_square
- validate_capture

### 4.4 chain_capture

Purpose:
Handle consecutive captures by the same piece during
the same player's turn.

Input:
- $a0 = Current square of the capturing piece

Output:
- $v0 = 1: Chain completed normally
- $v0 = 0: Invalid initial state

Shared variables:
- current_player
- board

Algorithm:
1. Receive the current square after the initial capture.
2. Check whether another capture is available.
3. Prompt the player for another landing square.
4. Call apply_capture.
5. If invalid, request another destination.
6. Update the current square after a successful capture.
7. Call check_promotion immediately.
8. Repeat until no further capture is available.

Dependencies:
- check_capture
- apply_capture
- check_promotion

Important:
The same piece and same player must continue throughout
the entire capture chain.

The initial capture and its promotion check must already
have been performed by the caller.

## 5. Testing

| Test | Scenario | Expected |
|---|---|---|
| C1 | Valid forward capture | Valid |
| C2 | No opponent between pieces | Invalid |
| C3 | Own piece in middle | Invalid |
| C4 | Occupied landing square | Invalid |
| C5 | Pawn captures backwards | Invalid |
| C6 | King captures backwards | Valid |
| C7 | Two consecutive captures | Valid chain |
| C8 | No further capture | End chain |
| C9 | Promotion during capture | Promote immediately |
| C10 | Invalid destination during chain | Reject move |

## 6. Integration Dependencies

This module depends on:
- board.asm
- coordinates.asm
- promotion.asm

It will be integrated with:
- movement.asm
- game_control.asm
- main.asm

## 7. Implementation Status

Update this section as development progresses.

- [x] validate_capture
- [x] apply_capture
- [x] check_capture
- [x] chain_capture
- [x] Independent testing
- [ ] Integration testing
