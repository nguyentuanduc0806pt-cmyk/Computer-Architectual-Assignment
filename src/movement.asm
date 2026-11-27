.data
.align 2
mv_dr: .word -1, -1,  1,  1
mv_dc: .word -1,  1, -1,  1

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


# ============================================================================
# HAS NORMAL MOVE
# Checks whether the piece at square $a0 belonging to player $a1 has at least
# one legal 1-square diagonal move. Does NOT modify the board.
#
# Input:  $a0 = square (1..32), $a1 = player (1 = Red, 3 = Black)
# Output: $v0 = 1 if at least one normal move exists, 0 otherwise
# ============================================================================
.globl has_normal_move
has_normal_move:
    addiu $sp, $sp, -24
    sw   $s0, 0($sp)
    sw   $s1, 4($sp)
    sw   $s2, 8($sp)
    sw   $s3, 12($sp)
    sw   $s4, 16($sp)
    sw   $ra, 20($sp)

    move $s0, $a0               # $s0 = square
    move $s1, $a1               # $s1 = player

    # Fast range check: 1..32
    slti $t0, $s0, 1
    bne  $t0, $zero, hnm_none
    slti $t0, $s0, 33
    beq  $t0, $zero, hnm_none

    # Fast ownership check on board[square - 1]
    la   $t0, board
    addiu $t1, $s0, -1
    addu $t0, $t0, $t1
    lbu  $t2, 0($t0)

    li   $t3, 1
    beq  $s1, $t3, hnm_check_red
    li   $t3, 3
    beq  $s1, $t3, hnm_check_black
    j    hnm_none

hnm_check_red:
    li   $t3, 1
    beq  $t2, $t3, hnm_owned
    li   $t3, 2
    beq  $t2, $t3, hnm_owned
    j    hnm_none

hnm_check_black:
    li   $t3, 3
    beq  $t2, $t3, hnm_owned
    li   $t3, 4
    beq  $t2, $t3, hnm_owned
    j    hnm_none

hnm_owned:
    move $a0, $s0
    jal  square_to_coord        # $v0 = row, $v1 = col
    move $s2, $v0               # $s2 = row
    move $s3, $v1               # $s3 = col

    li   $s4, 0                 # $s4 = direction index (0..3)

hnm_loop:
    slti $t0, $s4, 4
    beq  $t0, $zero, hnm_none

    sll  $t1, $s4, 2            # byte offset = i * 4
    la   $t2, mv_dr
    addu $t2, $t2, $t1
    lw   $t3, 0($t2)            # $t3 = dr
    la   $t2, mv_dc
    addu $t2, $t2, $t1
    lw   $t4, 0($t2)            # $t4 = dc

    addu $a0, $s2, $t3          # candidate row
    addu $a1, $s3, $t4          # candidate col
    jal  coord_to_square        # $v0 = candidate square or -1
    bltz $v0, hnm_next

    move $a0, $s0
    move $a1, $v0
    move $a2, $s1
    jal  validate_normal_move
    bne  $v0, $zero, hnm_found

hnm_next:
    addiu $s4, $s4, 1
    j    hnm_loop

hnm_found:
    li   $v0, 1
    j    hnm_done

hnm_none:
    li   $v0, 0

hnm_done:
    lw   $s0, 0($sp)
    lw   $s1, 4($sp)
    lw   $s2, 8($sp)
    lw   $s3, 12($sp)
    lw   $s4, 16($sp)
    lw   $ra, 20($sp)
    addiu $sp, $sp, 24
    jr   $ra


# ============================================================================
# PRINT NORMAL MOVES
# Prints all legal 1-square diagonal destination squares for the piece at $a0
# belonging to player $a1 (space-separated, ascending order). Read-only.
#
# Input:  $a0 = square (1..32), $a1 = player (1 = Red, 3 = Black)
# Output: $v0 = number of legal normal destinations printed
# ============================================================================
.globl print_normal_moves
print_normal_moves:
    addiu $sp, $sp, -32
    sw   $s0, 0($sp)
    sw   $s1, 4($sp)
    sw   $s2, 8($sp)
    sw   $s3, 12($sp)
    sw   $s4, 16($sp)
    sw   $s5, 20($sp)
    sw   $s6, 24($sp)
    sw   $ra, 28($sp)

    move $s0, $a0               # $s0 = square
    move $s1, $a1               # $s1 = player
    li   $s5, 0                 # $s5 = count of moves printed

    move $a0, $s0
    jal  square_to_coord
    bltz $v0, pnm_done
    move $s2, $v0               # $s2 = row
    move $s3, $v1               # $s3 = col

    li   $s4, 0                 # $s4 = direction index (0..3)

pnm_loop:
    slti $t0, $s4, 4
    beq  $t0, $zero, pnm_done

    sll  $t1, $s4, 2
    la   $t2, mv_dr
    addu $t2, $t2, $t1
    lw   $t3, 0($t2)
    la   $t2, mv_dc
    addu $t2, $t2, $t1
    lw   $t4, 0($t2)

    addu $a0, $s2, $t3
    addu $a1, $s3, $t4
    jal  coord_to_square
    bltz $v0, pnm_next

    move $s6, $v0               # save candidate square
    move $a0, $s0
    move $a1, $s6
    move $a2, $s1
    jal  validate_normal_move
    beq  $v0, $zero, pnm_next

    # Print space separator before 2nd+ items
    beq  $s5, $zero, pnm_print_num
    li   $a0, 32                # ' '
    li   $v0, 11
    syscall

pnm_print_num:
    move $a0, $s6
    li   $v0, 1
    syscall
    addiu $s5, $s5, 1

pnm_next:
    addiu $s4, $s4, 1
    j    pnm_loop

pnm_done:
    move $v0, $s5               # return count
    lw   $s0, 0($sp)
    lw   $s1, 4($sp)
    lw   $s2, 8($sp)
    lw   $s3, 12($sp)
    lw   $s4, 16($sp)
    lw   $s5, 20($sp)
    lw   $s6, 24($sp)
    lw   $ra, 28($sp)
    addiu $sp, $sp, 32
    jr   $ra
