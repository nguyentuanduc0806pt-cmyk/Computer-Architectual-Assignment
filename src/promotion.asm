.text

# ============================================================================
# CHECK PROMOTION
# Promotes a pawn on its opponent's back row (king-row) to a King.
# Works for both 8x8 (Black: 1..4, Red: 29..32) and 10x10 (Black: 1..5, Red: 46..50).
#
# Input: $a0 = destination square (1..num_squares)
# ============================================================================
.globl check_promotion
check_promotion:
    la   $t4, num_squares
    lw   $t4, 0($t4)            # 32 or 50
    la   $t5, squares_per_row
    lw   $t5, 0($t5)            # 4 or 5

    # 1. Guard against out-of-range square numbers (< 1 or > num_squares)
    slti $t0, $a0, 1
    bne  $t0, $zero, cp_done
    slt  $t0, $t4, $a0
    bne  $t0, $zero, cp_done

    # 2. Load piece at board[destination - 1]
    la   $t0, board
    addiu $t1, $a0, -1
    addu $t1, $t0, $t1
    lbu  $t2, 0($t1)

    # 3. Check Red pawn (1) reaching bottom row (sq > num_squares - squares_per_row)
    li   $t3, 1
    beq  $t2, $t3, cp_check_red

    # 4. Check Black pawn (3) reaching top row (sq <= squares_per_row)
    li   $t3, 3
    beq  $t2, $t3, cp_check_black

    # Empty (0) or already a King (2, 4) -> nothing to do
    j    cp_done

cp_check_red:
    subu $t6, $t4, $t5          # 28 (8x8) or 45 (10x10)
    slt  $t3, $t6, $a0          # Is (num_squares - squares_per_row) < sq?
    beq  $t3, $zero, cp_done
    li   $t3, 2                 # Promote to Red king (2)
    sb   $t3, 0($t1)
    jr   $ra

cp_check_black:
    slt  $t3, $t5, $a0          # Is squares_per_row < sq?
    bne  $t3, $zero, cp_done    # Not on row 0 -> do not promote
    li   $t3, 4                 # Promote to Black king (4)
    sb   $t3, 0($t1)

cp_done:
    jr   $ra
