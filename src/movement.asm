.text

.globl validate_normal_move
validate_normal_move:
    addi $sp, $sp, -24          # Allocate stack frame
    sw   $ra, 20($sp)
    sw   $s4, 16($sp)
    sw   $s3, 12($sp)
    sw   $s2, 8($sp)
    sw   $s1, 4($sp)
    sw   $s0, 0($sp)

    move $s0, $a0               # $s0 = start square
    move $s1, $a1               # $s1 = destination square

    # 1. Validate start in 1..32 and destination in 1..32
    slti $t0, $s0, 1
    bne  $t0, $zero, vnm_invalid
    slti $t0, $s0, 33
    beq  $t0, $zero, vnm_invalid

    slti $t0, $s1, 1
    bne  $t0, $zero, vnm_invalid
    slti $t0, $s1, 33
    beq  $t0, $zero, vnm_invalid

    # 2. Load piece at start square and verify ownership
    la   $t0, board
    addi $t1, $s0, -1           # start index = start - 1
    addu $t1, $t0, $t1
    lb   $s2, 0($t1)            # $s2 = piece code at start

    li   $t2, 1
    beq  $a2, $t2, vnm_check_red_owner
    li   $t2, 3
    beq  $a2, $t2, vnm_check_black_owner
    j    vnm_invalid            # Unknown player code

vnm_check_red_owner:
    li   $t2, 1                 # Red pawn
    beq  $s2, $t2, vnm_check_dest_empty
    li   $t2, 2                 # Red king
    beq  $s2, $t2, vnm_check_dest_empty
    j    vnm_invalid

vnm_check_black_owner:
    li   $t2, 3                 # Black pawn
    beq  $s2, $t2, vnm_check_dest_empty
    li   $t2, 4                 # Black king
    beq  $s2, $t2, vnm_check_dest_empty
    j    vnm_invalid

vnm_check_dest_empty:
    # 3. Verify destination square is empty (board[dest - 1] == 0)
    addi $t1, $s1, -1           # dest index = dest - 1
    addu $t1, $t0, $t1
    lb   $t2, 0($t1)
    bne  $t2, $zero, vnm_invalid

    # 4. Convert start and destination to (row, col)
    move $a0, $s0
    jal  square_to_coord        # $v0 = r1, $v1 = c1
    move $s3, $v0               # $s3 = r1
    move $s4, $v1               # $s4 = c1

    move $a0, $s1
    jal  square_to_coord        # $v0 = r2, $v1 = c2

    sub  $t0, $v0, $s3          # $t0 = d_row = r2 - r1
    sub  $t1, $v1, $s4          # $t1 = d_col = c2 - c1

    # 5. Check |d_col| == 1
    li   $t2, 1
    beq  $t1, $t2, vnm_check_drow
    li   $t2, -1
    beq  $t1, $t2, vnm_check_drow
    j    vnm_invalid

vnm_check_drow:
    # 6. Check d_row based on piece type (pawn vs king)
    li   $t2, 1                 # Red pawn: must move down (d_row == +1)
    beq  $s2, $t2, vnm_red_pawn_dir

    li   $t2, 3                 # Black pawn: must move up (d_row == -1)
    beq  $s2, $t2, vnm_black_pawn_dir

    # Kings (piece == 2 or 4): can move forward or backward (|d_row| == 1)
    li   $t2, 1
    beq  $t0, $t2, vnm_valid
    li   $t2, -1
    beq  $t0, $t2, vnm_valid
    j    vnm_invalid

vnm_red_pawn_dir:
    li   $t2, 1
    beq  $t0, $t2, vnm_valid
    j    vnm_invalid

vnm_black_pawn_dir:
    li   $t2, -1
    beq  $t0, $t2, vnm_valid

vnm_invalid:
    li   $v0, 0
    j    vnm_done

vnm_valid:
    li   $v0, 1

vnm_done:
    lw   $s0, 0($sp)            # Restore saved registers and stack frame
    lw   $s1, 4($sp)
    lw   $s2, 8($sp)
    lw   $s3, 12($sp)
    lw   $s4, 16($sp)
    lw   $ra, 20($sp)
    addi $sp, $sp, 24
    jr   $ra


.globl apply_normal_move
apply_normal_move:
    # Guard against out-of-range square numbers
    slti $t0, $a0, 1
    bne  $t0, $zero, anm_done
    slti $t0, $a0, 33
    beq  $t0, $zero, anm_done

    slti $t0, $a1, 1
    bne  $t0, $zero, anm_done
    slti $t0, $a1, 33
    beq  $t0, $zero, anm_done

    la   $t0, board
    addi $t1, $a0, -1           # start index = start - 1
    addu $t1, $t0, $t1          # $t1 = &board[start - 1]
    lb   $t2, 0($t1)            # $t2 = piece code

    addi $t3, $a1, -1           # dest index = dest - 1
    addu $t3, $t0, $t3          # $t3 = &board[dest - 1]
    sb   $t2, 0($t3)            # Place piece at destination
    sb   $zero, 0($t1)          # Clear start square

anm_done:
    jr   $ra
