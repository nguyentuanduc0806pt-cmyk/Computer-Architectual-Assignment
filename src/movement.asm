.data
.align 2
mv_dr: .word -1, -1,  1,  1
mv_dc: .word -1,  1, -1,  1

.text

# ============================================================================
# VALIDATE NORMAL MOVE
# Supports both:
#   - American Checkers (ruleset == 0): pawns 1-step forward, kings 1-step any diag
#   - International Checkers (ruleset == 1): pawns 1-step forward, Flying Kings
#     any distance along an unobstructed diagonal (forward or backward).
#
# Input:  $a0 = start square, $a1 = dest square, $a2 = player (1=Red, 3=Black)
# Output: $v0 = 1 if valid, 0 if invalid. Read-only (never mutates board).
# ============================================================================
.globl validate_normal_move
validate_normal_move:
    addiu $sp, $sp, -36
    sw   $ra, 32($sp)
    sw   $s7, 28($sp)
    sw   $s6, 24($sp)
    sw   $s5, 20($sp)
    sw   $s4, 16($sp)
    sw   $s3, 12($sp)
    sw   $s2, 8($sp)
    sw   $s1, 4($sp)
    sw   $s0, 0($sp)

    move $s0, $a0               # $s0 = start square
    move $s1, $a1               # $s1 = destination square

    # 1. Validate start and destination in 1..num_squares
    la   $t3, num_squares
    lw   $t3, 0($t3)

    slti $t0, $s0, 1
    bne  $t0, $zero, vnm_invalid
    slt  $t0, $t3, $s0
    bne  $t0, $zero, vnm_invalid

    slti $t0, $s1, 1
    bne  $t0, $zero, vnm_invalid
    slt  $t0, $t3, $s1
    bne  $t0, $zero, vnm_invalid

    beq  $s0, $s1, vnm_invalid

    # 2. Load piece at start square and verify ownership
    la   $t0, board
    addiu $t1, $s0, -1
    addu $t1, $t0, $t1
    lbu  $s2, 0($t1)            # $s2 = piece code at start

    li   $t2, 1
    beq  $a2, $t2, vnm_check_red_owner
    li   $t2, 3
    beq  $a2, $t2, vnm_check_black_owner
    j    vnm_invalid

vnm_check_red_owner:
    li   $t2, 1
    beq  $s2, $t2, vnm_check_dest_empty
    li   $t2, 2
    beq  $s2, $t2, vnm_check_dest_empty
    j    vnm_invalid

vnm_check_black_owner:
    li   $t2, 3
    beq  $s2, $t2, vnm_check_dest_empty
    li   $t2, 4
    beq  $s2, $t2, vnm_check_dest_empty
    j    vnm_invalid

vnm_check_dest_empty:
    # 3. Verify destination square is empty
    addiu $t1, $s1, -1
    addu $t1, $t0, $t1
    lbu  $t2, 0($t1)
    bne  $t2, $zero, vnm_invalid

    # 4. Convert start and destination to (row, col)
    move $a0, $s0
    jal  square_to_coord        # $v0 = r1, $v1 = c1
    move $s3, $v0               # $s3 = r1
    move $s4, $v1               # $s4 = c1

    move $a0, $s1
    jal  square_to_coord        # $v0 = r2, $v1 = c2
    move $s5, $v0               # $s5 = r2
    move $s6, $v1               # $s6 = c2

    sub  $t0, $s5, $s3          # $t0 = dr = r2 - r1
    sub  $t1, $s6, $s4          # $t1 = dc = c2 - c1

    # 5. Branch for International Flying King (ruleset == 1 and piece is 2 or 4)
    la   $t2, ruleset
    lw   $t2, 0($t2)
    beq  $t2, $zero, vnm_standard_step

    li   $t2, 2
    beq  $s2, $t2, vnm_flying_king
    li   $t2, 4
    beq  $s2, $t2, vnm_flying_king

vnm_standard_step:
    # Check |dc| == 1
    li   $t2, 1
    beq  $t1, $t2, vnm_check_drow
    li   $t2, -1
    beq  $t1, $t2, vnm_check_drow
    j    vnm_invalid

vnm_check_drow:
    li   $t2, 1                 # Red pawn: dr == +1
    beq  $s2, $t2, vnm_red_pawn_dir
    li   $t2, 3                 # Black pawn: dr == -1
    beq  $s2, $t2, vnm_black_pawn_dir

    # American King: |dr| == 1
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
    j    vnm_invalid

vnm_flying_king:
    # Must be on a diagonal: |dr| == |dc| and |dr| >= 1
    beq  $t0, $zero, vnm_invalid
    beq  $t1, $zero, vnm_invalid

    # Compute |dr| -> $t2, sr -> $s0 (reuse $s0 safely now)
    bgtz $t0, vnm_fk_dr_pos
    sub  $t2, $zero, $t0
    li   $s0, -1
    j    vnm_fk_dc
vnm_fk_dr_pos:
    move $t2, $t0
    li   $s0, 1

vnm_fk_dc:
    # Compute |dc| -> $t3, sc -> $s1 (reuse $s1 safely now)
    bgtz $t1, vnm_fk_dc_pos
    sub  $t3, $zero, $t1
    li   $s1, -1
    j    vnm_fk_check_diag
vnm_fk_dc_pos:
    move $t3, $t1
    li   $s1, 1

vnm_fk_check_diag:
    bne  $t2, $t3, vnm_invalid  # Not diagonal

    # Walk intermediate squares from (r1 + sr, c1 + sc) to (r2 - sr, c2 - sc)
    # $s3 = curr_r, $s4 = curr_c, $s7 = remaining intermediate steps = |dr| - 1
    addiu $s7, $t2, -1

vnm_fk_ray_loop:
    beq  $s7, $zero, vnm_valid  # All intermediate squares were empty

    addu $s3, $s3, $s0
    addu $s4, $s4, $s1

    move $a0, $s3
    move $a1, $s4
    jal  coord_to_square
    bltz $v0, vnm_invalid

    la   $t0, board
    addiu $t1, $v0, -1
    addu $t0, $t0, $t1
    lbu  $t2, 0($t0)
    bne  $t2, $zero, vnm_invalid # Path obstructed

    addiu $s7, $s7, -1
    j    vnm_fk_ray_loop

vnm_invalid:
    li   $v0, 0
    j    vnm_done

vnm_valid:
    li   $v0, 1

vnm_done:
    lw   $s0, 0($sp)
    lw   $s1, 4($sp)
    lw   $s2, 8($sp)
    lw   $s3, 12($sp)
    lw   $s4, 16($sp)
    lw   $s5, 20($sp)
    lw   $s6, 24($sp)
    lw   $s7, 28($sp)
    lw   $ra, 32($sp)
    addiu $sp, $sp, 36
    jr   $ra


# ============================================================================
# APPLY NORMAL MOVE
# Moves piece from $a0 to $a1 (1..num_squares) and clears $a0.
# ============================================================================
.globl apply_normal_move
apply_normal_move:
    la   $t4, num_squares
    lw   $t4, 0($t4)

    slti $t0, $a0, 1
    bne  $t0, $zero, anm_done
    slt  $t0, $t4, $a0
    bne  $t0, $zero, anm_done

    slti $t0, $a1, 1
    bne  $t0, $zero, anm_done
    slt  $t0, $t4, $a1
    bne  $t0, $zero, anm_done

    la   $t0, board
    addiu $t1, $a0, -1
    addu $t1, $t0, $t1
    lbu  $t2, 0($t1)

    addiu $t3, $a1, -1
    addu $t3, $t0, $t3
    sb   $t2, 0($t3)
    sb   $zero, 0($t1)

anm_done:
    jr   $ra


# ============================================================================
# HAS NORMAL MOVE
# Checks whether piece at $a0 belonging to player $a1 has at least one legal
# normal move (even for Flying Kings, a distance-1 diagonal move exists iff
# any diagonal move exists). Read-only.
#
# Input:  $a0 = square (1..num_squares), $a1 = player (1 = Red, 3 = Black)
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

    move $s0, $a0
    move $s1, $a1

    la   $t4, num_squares
    lw   $t4, 0($t4)
    slti $t0, $s0, 1
    bne  $t0, $zero, hnm_none
    slt  $t0, $t4, $s0
    bne  $t0, $zero, hnm_none

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
    jal  square_to_coord
    move $s2, $v0
    move $s3, $v1

    li   $s4, 0

hnm_loop:
    slti $t0, $s4, 4
    beq  $t0, $zero, hnm_none

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
# Prints all legal normal move destination squares from $a0 for player $a1.
# For International Flying Kings, prints all reachable empty squares along
# all 4 diagonal rays. Read-only.
#
# Input:  $a0 = square (1..num_squares), $a1 = player (1 = Red, 3 = Black)
# Output: $v0 = number of legal normal destinations printed
# ============================================================================
.globl print_normal_moves
print_normal_moves:
    addiu $sp, $sp, -36
    sw   $s0, 0($sp)
    sw   $s1, 4($sp)
    sw   $s2, 8($sp)
    sw   $s3, 12($sp)
    sw   $s4, 16($sp)
    sw   $s5, 20($sp)
    sw   $s6, 24($sp)
    sw   $s7, 28($sp)
    sw   $ra, 32($sp)

    move $s0, $a0               # $s0 = start square
    move $s1, $a1               # $s1 = player
    li   $s5, 0                 # $s5 = count printed

    move $a0, $s0
    jal  square_to_coord
    bltz $v0, pnm_done
    move $s2, $v0               # $s2 = start row
    move $s3, $v1               # $s3 = start col

    # Check if this piece is a Flying King (ruleset == 1 and piece is 2 or 4)
    li   $s7, 0                 # $s7 = 1 if flying king, 0 otherwise
    la   $t0, ruleset
    lw   $t0, 0($t0)
    beq  $t0, $zero, pnm_start_dirs

    la   $t0, board
    addiu $t1, $s0, -1
    addu $t0, $t0, $t1
    lbu  $t2, 0($t0)
    li   $t3, 2
    beq  $t2, $t3, pnm_is_fk
    li   $t3, 4
    beq  $t2, $t3, pnm_is_fk
    j    pnm_start_dirs
pnm_is_fk:
    li   $s7, 1

pnm_start_dirs:
    li   $s4, 0                 # $s4 = direction index (0..3)

pnm_dir_loop:
    slti $t0, $s4, 4
    beq  $t0, $zero, pnm_done

    li   $t5, 1                 # step distance k = 1

pnm_step_loop:
    sll  $t1, $s4, 2
    la   $t2, mv_dr
    addu $t2, $t2, $t1
    lw   $t3, 0($t2)            # dr
    la   $t2, mv_dc
    addu $t2, $t2, $t1
    lw   $t4, 0($t2)            # dc

    mul  $t3, $t3, $t5          # k * dr
    mul  $t4, $t4, $t5          # k * dc
    addu $a0, $s2, $t3
    addu $a1, $s3, $t4

    # Save k on stack? No, use $t5 only across non-clobbering? Wait: coord_to_square/validate clobber $t5!
    # So push k into $s6 before calling, or use a stack slot. Let's check: $s6 is free before candidate square!
    # Better: save $t5 in stack or compute r, c iteratively!
    # Actually we can just recompute or save k on stack: let's add 4 bytes or save in $s6 temporarily?
    # Wait: let's keep it ultra-clean by using $sp! No, let's check registers: we can allocate 40 bytes and store k at 36($sp)!
    j    pnm_step_exec

pnm_step_exec:
    # We'll store k in $s6 and candidate square in $v0 -> move to $t8? Syscalls don't clobber $t8, but jal might.
    # Let's just use $s6 for k!
    move $s6, $t5
    jal  coord_to_square
    bltz $v0, pnm_next_dir      # Off board -> stop this ray

    move $t8, $v0               # $t8 = candidate square (note: validate_normal_move does NOT use $t8!)
    # To be 100% ABI-safe across jal, save candidate square on stack:
    addiu $sp, $sp, -4
    sw   $v0, 0($sp)

    move $a0, $s0
    move $a1, $v0
    move $a2, $s1
    jal  validate_normal_move

    lw   $t9, 0($sp)
    addiu $sp, $sp, 4

    beq  $v0, $zero, pnm_next_dir # Blocked or invalid -> stop this ray

    # Print space separator before 2nd+ items
    beq  $s5, $zero, pnm_print_num
    li   $a0, 32
    li   $v0, 11
    syscall

pnm_print_num:
    move $a0, $t9
    li   $v0, 1
    syscall
    addiu $s5, $s5, 1

    # If not flying king, only check k = 1
    beq  $s7, $zero, pnm_next_dir

    addiu $t5, $s6, 1           # k++
    j    pnm_step_loop

pnm_next_dir:
    addiu $s4, $s4, 1
    j    pnm_dir_loop

pnm_done:
    move $v0, $s5
    lw   $s0, 0($sp)
    lw   $s1, 4($sp)
    lw   $s2, 8($sp)
    lw   $s3, 12($sp)
    lw   $s4, 16($sp)
    lw   $s5, 20($sp)
    lw   $s6, 24($sp)
    lw   $s7, 28($sp)
    lw   $ra, 32($sp)
    addiu $sp, $sp, 36
    jr   $ra
