.text

# ============================================================================
# SQUARE TO COORD
# Converts playable square number (1..num_squares) to (row, col) coordinates
# for both 8x8 (squares_per_row = 4, 1..32) and 10x10 (squares_per_row = 5, 1..50).
#
# Input:  $a0 = square number (1..32 or 1..50)
# Output: $v0 = row (0..board_dim-1), $v1 = col (0..board_dim-1)
#         or (-1, -1) if out of range
# ============================================================================
.globl square_to_coord
square_to_coord:
    la   $t3, num_squares
    lw   $t3, 0($t3)            # $t3 = 32 (8x8) or 50 (10x10)

    # Validate 1 <= square <= num_squares
    slti $t0, $a0, 1
    bne  $t0, $zero, s2c_invalid
    slt  $t0, $t3, $a0          # num_squares < square?
    bne  $t0, $zero, s2c_invalid

    la   $t4, squares_per_row
    lw   $t4, 0($t4)            # $t4 = 4 (8x8) or 5 (10x10)

    addiu $t0, $a0, -1          # idx = square - 1
    div  $t0, $t4
    mflo $v0                    # row = idx / squares_per_row
    mfhi $t1                    # rem = idx % squares_per_row
    andi $t2, $v0, 1            # row_parity = row % 2

    sll  $t1, $t1, 1            # 2 * rem
    addiu $t1, $t1, 1           # 2 * rem + 1
    subu $v1, $t1, $t2          # col = 2 * rem + 1 - (row % 2)
    jr   $ra

s2c_invalid:
    li   $v0, -1
    li   $v1, -1
    jr   $ra


# ============================================================================
# COORD TO SQUARE
# Converts (row, col) on a dark square into 1-based square number (1..num_squares).
# Supports both 8x8 and 10x10 using globals board_dim and squares_per_row.
#
# Input:  $a0 = row, $a1 = col
# Output: $v0 = square (1..num_squares) or -1 if out of bounds or light square
# ============================================================================
.globl coord_to_square
coord_to_square:
    la   $t3, board_dim
    lw   $t3, 0($t3)            # $t3 = 8 or 10

    # Validate 0 <= row < board_dim
    bltz $a0, c2s_invalid
    slt  $t0, $a0, $t3
    beq  $t0, $zero, c2s_invalid

    # Validate 0 <= col < board_dim
    bltz $a1, c2s_invalid
    slt  $t0, $a1, $t3
    beq  $t0, $zero, c2s_invalid

    # Validate playable dark square: (row + col) % 2 == 1
    addu $t0, $a0, $a1
    andi $t0, $t0, 1
    beq  $t0, $zero, c2s_invalid

    la   $t4, squares_per_row
    lw   $t4, 0($t4)            # $t4 = 4 or 5

    mul  $t0, $a0, $t4          # row * squares_per_row
    srl  $t1, $a1, 1            # col / 2
    addu $v0, $t0, $t1
    addiu $v0, $v0, 1           # + 1 for 1-based square number
    jr   $ra

c2s_invalid:
    li   $v0, -1
    jr   $ra
