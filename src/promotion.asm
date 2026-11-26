

.text


.globl check_promotion
check_promotion:
    # 1. Guard against out-of-range square numbers (< 1 or > 32)
    slti $t0, $a0, 1
    bne  $t0, $zero, cp_done
    slti $t0, $a0, 33
    beq  $t0, $zero, cp_done

    # 2. Load piece at board[destination - 1]
    la   $t0, board
    addi $t1, $a0, -1           # index = destination - 1 (0..31)
    addu $t1, $t0, $t1          # $t1 = &board[destination - 1]
    lbu  $t2, 0($t1)            # $t2 = piece code

    # 3. Check Red pawn (1) reaching bottom row (squares 29..32)
    li   $t3, 1
    beq  $t2, $t3, cp_check_red

    # 4. Check Black pawn (3) reaching top row (squares 1..4)
    li   $t3, 3
    beq  $t2, $t3, cp_check_black

    # Empty (0) or already a King (2, 4) -> nothing to do
    j    cp_done

cp_check_red:
    slti $t3, $a0, 29           # Is square < 29?
    bne  $t3, $zero, cp_done    # Not on row 7 -> do not promote
    li   $t3, 2                 # Promote to Red king (2)
    sb   $t3, 0($t1)
    jr   $ra

cp_check_black:
    slti $t3, $a0, 5            # Is square <= 4 (i.e. < 5)?
    beq  $t3, $zero, cp_done    # Not on row 0 -> do not promote
    li   $t3, 4                 # Promote to Black king (4)
    sb   $t3, 0($t1)

cp_done:
    jr   $ra
