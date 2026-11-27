# ============================================================================
# CAPTURE VALIDATION, EXECUTION, MULTI-JUMP PATHS & MAX-CAPTURE ENGINE
# Supports:
#   - American/English Checkers (ruleset == 0, 8x8):
#       * Pawns capture forward only (2 sq diag); Kings capture all 4 dirs (2 sq).
#       * Any legal capture piece/path allowed; multi-jump mandatory until done.
#       * Promotion on king-row immediately ends the turn.
#   - International Checkers (ruleset == 1, 10x10):
#       * Pawns capture forward AND backward (2 sq diag).
#       * Flying Kings capture at any distance & land on any empty sq beyond.
#       * Captured pieces stay marked (cannot be jumped twice) until chain ends.
#       * Maximum capture rule enforced across all pieces and paths.
#       * Promotion occurs only if a pawn ENDS its turn on the king-row.
# ============================================================================
.data

.align 2
cap_unit_dr: .word -1, -1,  1,  1
cap_unit_dc: .word -1,  1, -1,  1

# Static path buffer for printing complete multi-jump capture chains
path_buf:    .space 100         # Up to 25 squares (words) in a single chain
path_len:    .word 0

chain_avail_msg:
    .asciiz "Available chain landing squares: "

chain_paths_msg:
    .asciiz "  Remaining capture paths:\n"

chain_prompt_msg:
    .asciiz "Chaining possible. Enter landing square: "

chain_invalid_msg:
    .asciiz "Not a valid capture (or does not achieve maximum capture)! Try another landing square.\n"

chain_finished_msg:
    .asciiz "No further capture available. Chain complete.\n"

cap_fb_red_msg:
    .asciiz "Captured Red's piece! ("

cap_fb_black_msg:
    .asciiz "Captured Black's piece! ("

cap_fb_close_msg:
    .asciiz ")\n"

chain_promo_pre_msg:
    .asciiz "Promoted to King at square "

chain_promo_post_msg:
    .asciiz "! Turn ends.\n"

path_indent_msg:
    .asciiz "    "

.text

# ============================================================================
# HELPER: IS KING ROW FOR PAWN
# Input:  $a0 = square (1..num_squares), $a1 = piece code (1..4)
# Output: $v0 = 1 if $a1 is a pawn standing on its promotion row, else 0
# ============================================================================
is_king_row_for_pawn:
    la   $t0, num_squares
    lw   $t0, 0($t0)
    la   $t1, squares_per_row
    lw   $t1, 0($t1)

    li   $t2, 1
    beq  $a1, $t2, ikr_red
    li   $t2, 3
    beq  $a1, $t2, ikr_black
    li   $v0, 0
    jr   $ra

ikr_red:
    subu $t2, $t0, $t1          # 28 (8x8) or 45 (10x10)
    slt  $v0, $t2, $a0          # 1 if sq > 28 (or > 45)
    jr   $ra

ikr_black:
    slt  $t2, $t1, $a0          # 1 if sq > 4 (or > 5)
    xori $v0, $t2, 1            # 1 if sq <= squares_per_row
    jr   $ra


# ============================================================================
# FIND CAPTURED SQUARE
# Read-only core validator for a single capture hop.
# Supports American pawns/kings, International pawns (fwd+bwd), and
# International Flying Kings (any distance along a diagonal over exactly 1
# uncaptured opponent piece).
#
# Input:  $a0 = start square, $a1 = dest square, $a2 = player (1=Red, 3=Black)
# Output: $v0 = square number (1..num_squares) of captured opponent piece,
#               or 0 if the capture is invalid.
# ============================================================================
.globl find_captured_square
find_captured_square:
    addiu $sp, $sp, -40
    sw   $s0, 0($sp)
    sw   $s1, 4($sp)
    sw   $s2, 8($sp)
    sw   $s3, 12($sp)
    sw   $s4, 16($sp)
    sw   $s5, 20($sp)
    sw   $s6, 24($sp)
    sw   $s7, 28($sp)
    sw   $ra, 32($sp)

    move $s0, $a0               # $s0 = start
    move $s1, $a1               # $s1 = dest
    move $s2, $a2               # $s2 = player

    # 1. Range checks: 1..num_squares and start != dest
    la   $t3, num_squares
    lw   $t3, 0($t3)

    slti $t0, $s0, 1
    bne  $t0, $zero, fcs_invalid
    slt  $t0, $t3, $s0
    bne  $t0, $zero, fcs_invalid

    slti $t0, $s1, 1
    bne  $t0, $zero, fcs_invalid
    slt  $t0, $t3, $s1
    bne  $t0, $zero, fcs_invalid

    beq  $s0, $s1, fcs_invalid

    # 2. Check player & ownership of start piece
    la   $t0, board
    addiu $t1, $s0, -1
    addu $t0, $t0, $t1
    lbu  $s3, 0($t0)            # $s3 = start piece code

    li   $t0, 1
    beq  $s2, $t0, fcs_own_red
    li   $t0, 3
    beq  $s2, $t0, fcs_own_black
    j    fcs_invalid

fcs_own_red:
    li   $t0, 1
    beq  $s3, $t0, fcs_own_ok
    li   $t0, 2
    beq  $s3, $t0, fcs_own_ok
    j    fcs_invalid

fcs_own_black:
    li   $t0, 3
    beq  $s3, $t0, fcs_own_ok
    li   $t0, 4
    beq  $s3, $t0, fcs_own_ok
    j    fcs_invalid

fcs_own_ok:
    # 3. Destination must be empty AND not marked in captured_mask
    la   $t0, board
    addiu $t1, $s1, -1
    addu $t0, $t0, $t1
    lbu  $t2, 0($t0)
    bne  $t2, $zero, fcs_invalid

    la   $t0, captured_mask
    addu $t0, $t0, $t1
    lbu  $t2, 0($t0)
    bne  $t2, $zero, fcs_invalid

    # 4. Coordinates of start and destination
    move $a0, $s0
    jal  square_to_coord
    move $s4, $v0               # $s4 = r1
    move $s5, $v1               # $s5 = c1

    move $a0, $s1
    jal  square_to_coord
    move $s6, $v0               # $s6 = r2
    move $s7, $v1               # $s7 = c2

    sub  $t0, $s6, $s4          # $t0 = dr
    sub  $t1, $s7, $s5          # $t1 = dc

    # 5. Check if International Flying King (ruleset == 1 and piece is 2 or 4)
    la   $t2, ruleset
    lw   $t2, 0($t2)
    beq  $t2, $zero, fcs_short_jump

    li   $t2, 2
    beq  $s3, $t2, fcs_flying_king
    li   $t2, 4
    beq  $s3, $t2, fcs_flying_king

    # ------------------------------------------------
    # SHORT JUMP (2x2 diagonal): American pawns/kings & International pawns
    # ------------------------------------------------
fcs_short_jump:
    li   $t2, 2
    beq  $t0, $t2, fcs_sj_row_ok
    li   $t2, -2
    bne  $t0, $t2, fcs_invalid

fcs_sj_row_ok:
    li   $t2, 2
    beq  $t1, $t2, fcs_sj_col_ok
    li   $t2, -2
    bne  $t1, $t2, fcs_invalid

fcs_sj_col_ok:
    # Direction restriction applies ONLY to pawns in American Checkers (ruleset == 0)
    la   $t2, ruleset
    lw   $t2, 0($t2)
    bne  $t2, $zero, fcs_sj_middle # International pawns capture forward & backward!

    li   $t2, 1
    beq  $s3, $t2, fcs_sj_red_dir
    li   $t2, 3
    beq  $s3, $t2, fcs_sj_blk_dir
    j    fcs_sj_middle          # Kings capture both directions

fcs_sj_red_dir:
    li   $t2, 2
    bne  $t0, $t2, fcs_invalid
    j    fcs_sj_middle

fcs_sj_blk_dir:
    li   $t2, -2
    bne  $t0, $t2, fcs_invalid

fcs_sj_middle:
    addu $a0, $s4, $s6
    srl  $a0, $a0, 1            # mid_r
    addu $a1, $s5, $s7
    srl  $a1, $a1, 1            # mid_c
    jal  coord_to_square
    bltz $v0, fcs_invalid

    move $s0, $v0               # $s0 = mid_sq
    addiu $t0, $s0, -1

    # Must not already be captured in this chain
    la   $t1, captured_mask
    addu $t1, $t1, $t0
    lbu  $t2, 0($t1)
    bne  $t2, $zero, fcs_invalid

    la   $t1, board
    addu $t1, $t1, $t0
    lbu  $t2, 0($t1)            # middle piece
    beq  $t2, $zero, fcs_invalid

    # Verify middle piece belongs to opponent
    li   $t0, 1
    beq  $s2, $t0, fcs_sj_red_cap
    # Black captures Red (1 or 2)
    li   $t0, 1
    beq  $t2, $t0, fcs_sj_valid
    li   $t0, 2
    beq  $t2, $t0, fcs_sj_valid
    j    fcs_invalid

fcs_sj_red_cap:
    # Red captures Black (3 or 4)
    li   $t0, 3
    beq  $t2, $t0, fcs_sj_valid
    li   $t0, 4
    beq  $t2, $t0, fcs_sj_valid
    j    fcs_invalid

fcs_sj_valid:
    move $v0, $s0               # Return mid_sq
    j    fcs_done

    # ------------------------------------------------
    # FLYING KING CAPTURE (International ruleset == 1)
    # Must be diagonal with |dr| == |dc| >= 2, and strictly between start & dest
    # there must be EXACTLY ONE opponent piece (not in captured_mask) and 0 own pieces.
    # ------------------------------------------------
fcs_flying_king:
    # |dr| -> $t2, sr -> $s0
    bgtz $t0, fcs_fk_dr_pos
    sub  $t2, $zero, $t0
    li   $s0, -1
    j    fcs_fk_dc
fcs_fk_dr_pos:
    move $t2, $t0
    li   $s0, 1

fcs_fk_dc:
    # |dc| -> $t3, sc -> $s1
    bgtz $t1, fcs_fk_dc_pos
    sub  $t3, $zero, $t1
    li   $s1, -1
    j    fcs_fk_check
fcs_fk_dc_pos:
    move $t3, $t1
    li   $s1, 1

fcs_fk_check:
    bne  $t2, $t3, fcs_invalid  # Not diagonal
    slti $t4, $t2, 2
    bne  $t4, $zero, fcs_invalid # Distance must be >= 2

    # Walk intermediate squares:
    # $s4 = curr_r, $s5 = curr_c, $s6 = remaining steps (|dr| - 1), $s7 = found_enemy_sq (0 initially)
    addiu $s6, $t2, -1
    li   $s7, 0

fcs_fk_loop:
    beq  $s6, $zero, fcs_fk_finish

    addu $s4, $s4, $s0
    addu $s5, $s5, $s1

    move $a0, $s4
    move $a1, $s5
    jal  coord_to_square
    bltz $v0, fcs_invalid

    move $t4, $v0               # $t4 = intermediate sq
    addiu $t0, $t4, -1

    # Cannot jump over an already-captured piece
    la   $t1, captured_mask
    addu $t1, $t1, $t0
    lbu  $t2, 0($t1)
    bne  $t2, $zero, fcs_invalid

    la   $t1, board
    addu $t1, $t1, $t0
    lbu  $t2, 0($t1)
    beq  $t2, $zero, fcs_fk_next # Empty square -> keep flying

    # Occupied square: check if opponent or own piece
    li   $t0, 1
    beq  $s2, $t0, fcs_fk_chk_black_opp
    # Player is Black -> opponent is 1 or 2
    li   $t0, 1
    beq  $t2, $t0, fcs_fk_hit_opp
    li   $t0, 2
    beq  $t2, $t0, fcs_fk_hit_opp
    j    fcs_invalid            # Own piece blocks ray

fcs_fk_chk_black_opp:
    # Player is Red -> opponent is 3 or 4
    li   $t0, 3
    beq  $t2, $t0, fcs_fk_hit_opp
    li   $t0, 4
    beq  $t2, $t0, fcs_fk_hit_opp
    j    fcs_invalid            # Own piece blocks ray

fcs_fk_hit_opp:
    bne  $s7, $zero, fcs_invalid # Already jumped an opponent -> cannot jump 2 in 1 hop
    move $s7, $t4               # Record captured opponent square

fcs_fk_next:
    addiu $s6, $s6, -1
    j    fcs_fk_loop

fcs_fk_finish:
    move $v0, $s7               # 0 if no opponent jumped, else captured sq
    j    fcs_done

fcs_invalid:
    li   $v0, 0

fcs_done:
    lw   $s0, 0($sp)
    lw   $s1, 4($sp)
    lw   $s2, 8($sp)
    lw   $s3, 12($sp)
    lw   $s4, 16($sp)
    lw   $s5, 20($sp)
    lw   $s6, 24($sp)
    lw   $s7, 28($sp)
    lw   $ra, 32($sp)
    addiu $sp, $sp, 40
    jr   $ra


# ============================================================================
# VALIDATE CAPTURE
# Input:  $a0 = start square, $a1 = dest square, $a2 = player (1=Red, 3=Black)
# Output: $v0 = 1 if capture is valid, 0 otherwise. Read-only.
# ============================================================================
.globl validate_capture
validate_capture:
    addiu $sp, $sp, -4
    sw   $ra, 0($sp)

    jal  find_captured_square
    beq  $v0, $zero, vc_ret_zero
    li   $v0, 1
    j    vc_ret
vc_ret_zero:
    li   $v0, 0
vc_ret:
    lw   $ra, 0($sp)
    addiu $sp, $sp, 4
    jr   $ra


# ============================================================================
# APPLY CAPTURE
# Input:  $a0 = start square, $a1 = dest square (uses global current_player)
# Output: $v0 = 1 if executed, 0 if invalid
# In International mode with in_capture_chain == 1, marks captured piece in
# captured_mask (deferred removal until finalize_captured_pieces).
# ============================================================================
.globl apply_capture
apply_capture:
    addiu $sp, $sp, -20
    sw   $s0, 0($sp)
    sw   $s1, 4($sp)
    sw   $s2, 8($sp)
    sw   $s3, 12($sp)
    sw   $ra, 16($sp)

    move $s0, $a0               # start
    move $s1, $a1               # dest

    la   $t0, current_player
    lw   $a2, 0($t0)
    move $a0, $s0
    move $a1, $s1
    jal  find_captured_square
    beq  $v0, $zero, ac_invalid
    move $s3, $v0               # $s3 = captured square

    # Move piece from start to dest
    la   $t0, board
    addiu $t1, $s0, -1
    addu $t2, $t0, $t1
    lbu  $s2, 0($t2)            # moving piece

    addiu $t1, $s1, -1
    addu $t3, $t0, $t1

    sb   $zero, 0($t2)          # clear start
    sb   $s2, 0($t3)            # place at dest

    # Check if International deferred removal is active
    la   $t4, ruleset
    lw   $t4, 0($t4)
    beq  $t4, $zero, ac_remove_now
    la   $t4, in_capture_chain
    lw   $t4, 0($t4)
    beq  $t4, $zero, ac_remove_now

    # Deferred removal: mark in captured_mask
    la   $t4, captured_mask
    addiu $t1, $s3, -1
    addu $t4, $t4, $t1
    li   $t5, 1
    sb   $t5, 0($t4)
    j    ac_success

ac_remove_now:
    addiu $t1, $s3, -1
    addu $t4, $t0, $t1
    sb   $zero, 0($t4)          # remove captured piece immediately

ac_success:
    li   $v0, 1
    j    ac_done

ac_invalid:
    li   $v0, 0

ac_done:
    lw   $s0, 0($sp)
    lw   $s1, 4($sp)
    lw   $s2, 8($sp)
    lw   $s3, 12($sp)
    lw   $ra, 16($sp)
    addiu $sp, $sp, 20
    jr   $ra


# ============================================================================
# FINALIZE CAPTURED PIECES
# Removes all pieces marked in captured_mask from board[], clears captured_mask,
# and resets in_capture_chain = 0.
# ============================================================================
.globl finalize_captured_pieces
finalize_captured_pieces:
    la   $t0, board
    la   $t1, captured_mask
    li   $t2, 0
    li   $t3, 50

fcp_loop:
    beq  $t2, $t3, fcp_done
    lbu  $t4, 0($t1)
    beq  $t4, $zero, fcp_next
    sb   $zero, 0($t0)          # Remove captured piece from board
    sb   $zero, 0($t1)          # Clear mask
fcp_next:
    addiu $t0, $t0, 1
    addiu $t1, $t1, 1
    addiu $t2, $t2, 1
    j    fcp_loop

fcp_done:
    la   $t0, in_capture_chain
    sw   $zero, 0($t0)
    jr   $ra


# ============================================================================
# HAS CAPTURE FROM
# Checks whether piece at $a0 belonging to player $a1 has at least one legal
# single-hop capture (including Flying King long-range captures in Intl mode).
# Read-only.
#
# Input:  $a0 = square (1..num_squares), $a1 = player (1=Red, 3=Black)
# Output: $v0 = 1 if capture exists, 0 otherwise
# ============================================================================
.globl has_capture_from
has_capture_from:
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

    move $s0, $a0               # sq
    move $s1, $a1               # player

    la   $t4, num_squares
    lw   $t4, 0($t4)
    slti $t0, $s0, 1
    bne  $t0, $zero, hcf_none
    slt  $t0, $t4, $s0
    bne  $t0, $zero, hcf_none

    # Ownership check
    la   $t0, board
    addiu $t1, $s0, -1
    addu $t0, $t0, $t1
    lbu  $t2, 0($t0)

    li   $t3, 1
    beq  $s1, $t3, hcf_check_red
    li   $t3, 3
    beq  $s1, $t3, hcf_check_black
    j    hcf_none

hcf_check_red:
    li   $t3, 1
    beq  $t2, $t3, hcf_owned
    li   $t3, 2
    beq  $t2, $t3, hcf_owned
    j    hcf_none

hcf_check_black:
    li   $t3, 3
    beq  $t2, $t3, hcf_owned
    li   $t3, 4
    beq  $t2, $t3, hcf_owned
    j    hcf_none

hcf_owned:
    # Determine if Flying King ($s7 = 1 if ruleset == 1 and piece is 2 or 4)
    li   $s7, 0
    la   $t0, ruleset
    lw   $t0, 0($t0)
    beq  $t0, $zero, hcf_get_coord
    li   $t3, 2
    beq  $t2, $t3, hcf_is_fk
    li   $t3, 4
    beq  $t2, $t3, hcf_is_fk
    j    hcf_get_coord
hcf_is_fk:
    li   $s7, 1

hcf_get_coord:
    move $a0, $s0
    jal  square_to_coord
    move $s2, $v0               # row
    move $s3, $v1               # col

    li   $s4, 0                 # dir index 0..3

hcf_dir_loop:
    slti $t0, $s4, 4
    beq  $t0, $zero, hcf_none

    li   $s5, 2                 # step distance k = 2

hcf_step_loop:
    sll  $t1, $s4, 2
    la   $t2, cap_unit_dr
    addu $t2, $t2, $t1
    lw   $t3, 0($t2)
    la   $t2, cap_unit_dc
    addu $t2, $t2, $t1
    lw   $t4, 0($t2)

    mul  $t3, $t3, $s5
    mul  $t4, $t4, $s5
    addu $a0, $s2, $t3
    addu $a1, $s3, $t4
    jal  coord_to_square
    bltz $v0, hcf_next_dir      # Off board -> end ray

    move $a0, $s0
    move $a1, $v0
    move $a2, $s1
    jal  validate_capture
    bne  $v0, $zero, hcf_found

    beq  $s7, $zero, hcf_next_dir # Not flying king -> only k = 2
    addiu $s5, $s5, 1
    j    hcf_step_loop

hcf_next_dir:
    addiu $s4, $s4, 1
    j    hcf_dir_loop

hcf_found:
    li   $v0, 1
    j    hcf_done

hcf_none:
    li   $v0, 0

hcf_done:
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
# CHECK CAPTURE
# Wrapper around has_capture_from using global current_player.
# Input:  $a0 = current square
# Output: $v0 = 1 if capture exists, 0 otherwise
# ============================================================================
.globl check_capture
check_capture:
    la   $t0, current_player
    lw   $a1, 0($t0)
    j    has_capture_from


# ============================================================================
# HAS ANY CAPTURE
# Scans 1..num_squares to check whether player $a0 has any legal capture.
# ============================================================================
.globl has_any_capture
has_any_capture:
    addiu $sp, $sp, -16
    sw   $s0, 0($sp)
    sw   $s1, 4($sp)
    sw   $s2, 8($sp)
    sw   $ra, 12($sp)

    move $s0, $a0
    li   $s1, 1
    la   $t0, num_squares
    lw   $s2, 0($t0)

hac_loop:
    slt  $t0, $s2, $s1          # num_squares < sq?
    bne  $t0, $zero, hac_none

    move $a0, $s1
    move $a1, $s0
    jal  has_capture_from
    bne  $v0, $zero, hac_found

    addiu $s1, $s1, 1
    j    hac_loop

hac_found:
    li   $v0, 1
    j    hac_done

hac_none:
    li   $v0, 0

hac_done:
    lw   $s0, 0($sp)
    lw   $s1, 4($sp)
    lw   $s2, 8($sp)
    lw   $ra, 12($sp)
    addiu $sp, $sp, 16
    jr   $ra


# ============================================================================
# MAX CAPTURE FROM (RECURSIVE DFS)
# Computes the maximum number of pieces that can be captured in a single turn
# starting from square $a0 for player $a1. Restores board & captured_mask
# completely before returning.
#
# Input:  $a0 = start square, $a1 = player (1=Red, 3=Black)
# Output: $v0 = maximum capture count (0 if no capture possible)
# ============================================================================
.globl max_capture_from
max_capture_from:
    addiu $sp, $sp, -52
    sw   $s0, 0($sp)
    sw   $s1, 4($sp)
    sw   $s2, 8($sp)
    sw   $s3, 12($sp)
    sw   $s4, 16($sp)
    sw   $s5, 20($sp)
    sw   $s6, 24($sp)
    sw   $s7, 28($sp)
    sw   $ra, 32($sp)
    # 36($sp) = best_depth
    # 40($sp) = piece_code
    # 44($sp) = is_flying_king
    # 48($sp) = old_captured_piece (for American undo)

    move $s0, $a0               # $s0 = sq
    move $s1, $a1               # $s1 = player
    sw   $zero, 36($sp)         # best = 0

    la   $t4, num_squares
    lw   $t4, 0($t4)
    slti $t0, $s0, 1
    bne  $t0, $zero, mcf_done
    slt  $t0, $t4, $s0
    bne  $t0, $zero, mcf_done

    la   $t0, board
    addiu $t1, $s0, -1
    addu $t0, $t0, $t1
    lbu  $t2, 0($t0)            # piece code
    sw   $t2, 40($sp)

    # Verify ownership
    li   $t3, 1
    beq  $s1, $t3, mcf_own_red
    li   $t3, 3
    beq  $s1, $t3, mcf_own_blk
    j    mcf_done

mcf_own_red:
    li   $t3, 1
    beq  $t2, $t3, mcf_own_ok
    li   $t3, 2
    beq  $t2, $t3, mcf_own_ok
    j    mcf_done

mcf_own_blk:
    li   $t3, 3
    beq  $t2, $t3, mcf_own_ok
    li   $t3, 4
    beq  $t2, $t3, mcf_own_ok
    j    mcf_done

mcf_own_ok:
    # Determine if Flying King
    li   $t5, 0
    la   $t0, ruleset
    lw   $t0, 0($t0)
    beq  $t0, $zero, mcf_store_fk
    li   $t3, 2
    beq  $t2, $t3, mcf_set_fk
    li   $t3, 4
    beq  $t2, $t3, mcf_set_fk
    j    mcf_store_fk
mcf_set_fk:
    li   $t5, 1
mcf_store_fk:
    sw   $t5, 44($sp)

    move $a0, $s0
    jal  square_to_coord
    move $s2, $v0               # $s2 = r
    move $s3, $v1               # $s3 = c

    li   $s4, 0                 # $s4 = dir index 0..3

mcf_dir_loop:
    slti $t0, $s4, 4
    beq  $t0, $zero, mcf_done

    li   $s5, 2                 # $s5 = step k = 2

mcf_step_loop:
    sll  $t1, $s4, 2
    la   $t2, cap_unit_dr
    addu $t2, $t2, $t1
    lw   $t3, 0($t2)
    la   $t2, cap_unit_dc
    addu $t2, $t2, $t1
    lw   $t4, 0($t2)

    mul  $t3, $t3, $s5
    mul  $t4, $t4, $s5
    addu $a0, $s2, $t3
    addu $a1, $s3, $t4
    jal  coord_to_square
    bltz $v0, mcf_next_dir      # Off board -> stop ray

    move $s6, $v0               # $s6 = dest sq

    move $a0, $s0
    move $a1, $s6
    move $a2, $s1
    jal  find_captured_square
    beq  $v0, $zero, mcf_next_step
    move $s7, $v0               # $s7 = cap_sq

    # --- Temporarily apply hop ---
    lw   $t2, 40($sp)           # piece
    la   $t0, board
    addiu $t1, $s0, -1
    addu $t1, $t0, $t1
    sb   $zero, 0($t1)          # board[sq-1] = 0

    addiu $t1, $s6, -1
    addu $t1, $t0, $t1
    sb   $t2, 0($t1)            # board[dest-1] = piece

    addiu $t1, $s7, -1
    addu $t3, $t0, $t1
    lbu  $t4, 0($t3)
    sw   $t4, 48($sp)           # save old_captured_piece

    la   $t5, ruleset
    lw   $t5, 0($t5)
    beq  $t5, $zero, mcf_tmp_am

    # International: mark captured_mask[cap_sq-1] = 1 (leave piece on board)
    la   $t6, captured_mask
    addu $t6, $t6, $t1
    li   $t7, 1
    sb   $t7, 0($t6)

    move $a0, $s6
    move $a1, $s1
    jal  max_capture_from       # $v0 = sub_depth

    # Undo International
    la   $t6, captured_mask
    addiu $t1, $s7, -1
    addu $t6, $t6, $t1
    sb   $zero, 0($t6)
    j    mcf_undo_piece

mcf_tmp_am:
    # American: remove captured piece immediately
    sb   $zero, 0($t3)

    # If pawn reached king-row in American mode, turn ends immediately (sub = 0)
    move $a0, $s6
    lw   $a1, 40($sp)
    jal  is_king_row_for_pawn
    bne  $v0, $zero, mcf_am_promo_stop

    move $a0, $s6
    move $a1, $s1
    jal  max_capture_from       # $v0 = sub_depth
    j    mcf_undo_am

mcf_am_promo_stop:
    li   $v0, 0

mcf_undo_am:
    la   $t0, board
    addiu $t1, $s7, -1
    addu $t3, $t0, $t1
    lw   $t4, 48($sp)
    sb   $t4, 0($t3)            # restore captured piece

mcf_undo_piece:
    # Restore moving piece: board[sq-1] = piece, board[dest-1] = 0
    la   $t0, board
    lw   $t2, 40($sp)
    addiu $t1, $s0, -1
    addu $t1, $t0, $t1
    sb   $t2, 0($t1)

    addiu $t1, $s6, -1
    addu $t1, $t0, $t1
    sb   $zero, 0($t1)

    # Update best = max(best, 1 + $v0)
    addiu $t0, $v0, 1
    lw   $t1, 36($sp)
    slt  $t2, $t1, $t0
    beq  $t2, $zero, mcf_next_step
    sw   $t0, 36($sp)

mcf_next_step:
    lw   $t5, 44($sp)
    beq  $t5, $zero, mcf_next_dir # Not flying king -> only k = 2
    addiu $s5, $s5, 1
    j    mcf_step_loop

mcf_next_dir:
    addiu $s4, $s4, 1
    j    mcf_dir_loop

mcf_done:
    lw   $v0, 36($sp)
    lw   $s0, 0($sp)
    lw   $s1, 4($sp)
    lw   $s2, 8($sp)
    lw   $s3, 12($sp)
    lw   $s4, 16($sp)
    lw   $s5, 20($sp)
    lw   $s6, 24($sp)
    lw   $s7, 28($sp)
    lw   $ra, 32($sp)
    addiu $sp, $sp, 52
    jr   $ra


# ============================================================================
# MAX CAPTURE FOR PLAYER
# Returns the maximum number of pieces player $a0 can capture with ANY piece.
# Input:  $a0 = player (1=Red, 3=Black)
# Output: $v0 = global maximum capture count
# ============================================================================
.globl max_capture_for_player
max_capture_for_player:
    addiu $sp, $sp, -20
    sw   $s0, 0($sp)
    sw   $s1, 4($sp)
    sw   $s2, 8($sp)
    sw   $s3, 12($sp)
    sw   $ra, 16($sp)

    move $s0, $a0               # player
    li   $s1, 1                 # sq = 1..num_squares
    la   $t0, num_squares
    lw   $s2, 0($t0)
    li   $s3, 0                 # global_max = 0

mcpl_loop:
    slt  $t0, $s2, $s1
    bne  $t0, $zero, mcpl_done

    move $a0, $s1
    move $a1, $s0
    jal  max_capture_from
    slt  $t0, $s3, $v0
    beq  $t0, $zero, mcpl_next
    move $s3, $v0

mcpl_next:
    addiu $s1, $s1, 1
    j    mcpl_loop

mcpl_done:
    move $v0, $s3
    lw   $s0, 0($sp)
    lw   $s1, 4($sp)
    lw   $s2, 8($sp)
    lw   $s3, 12($sp)
    lw   $ra, 16($sp)
    addiu $sp, $sp, 20
    jr   $ra


# ============================================================================
# IS CAPTURE ALLOWED
# Validates a capture hop AND (in International mode) enforces the Maximum
# Capture rule from the starting square.
#
# Input:  $a0 = start sq, $a1 = dest sq, $a2 = player (1=Red, 3=Black)
# Output: $v0 = 1 if allowed, 0 otherwise. Read-only.
# ============================================================================
.globl is_capture_allowed
is_capture_allowed:
    addiu $sp, $sp, -32
    sw   $s0, 0($sp)
    sw   $s1, 4($sp)
    sw   $s2, 8($sp)
    sw   $s3, 12($sp)
    sw   $s4, 16($sp)
    sw   $s5, 20($sp)
    sw   $ra, 24($sp)

    move $s0, $a0               # start
    move $s1, $a1               # dest
    move $s2, $a2               # player

    jal  find_captured_square
    beq  $v0, $zero, ica_no
    move $s3, $v0               # $s3 = cap_sq

    # In American mode, any valid capture is allowed
    la   $t0, ruleset
    lw   $t0, 0($t0)
    beq  $t0, $zero, ica_yes

    # International mode: verify 1 + max_capture_from(dest) == max_capture_from(start)
    move $a0, $s0
    move $a1, $s2
    jal  max_capture_from
    move $s4, $v0               # $s4 = required max from start

    # Temporarily move piece & mark cap_sq
    la   $t0, board
    addiu $t1, $s0, -1
    addu $t1, $t0, $t1
    lbu  $s5, 0($t1)            # $s5 = piece
    sb   $zero, 0($t1)

    addiu $t1, $s1, -1
    addu $t1, $t0, $t1
    sb   $s5, 0($t1)

    la   $t2, captured_mask
    addiu $t1, $s3, -1
    addu $t2, $t2, $t1
    li   $t3, 1
    sb   $t3, 0($t2)

    move $a0, $s1
    move $a1, $s2
    jal  max_capture_from
    addiu $t4, $v0, 1           # $t4 = 1 + sub_max

    # Undo
    la   $t0, board
    addiu $t1, $s0, -1
    addu $t1, $t0, $t1
    sb   $s5, 0($t1)

    addiu $t1, $s1, -1
    addu $t1, $t0, $t1
    sb   $zero, 0($t1)

    la   $t2, captured_mask
    addiu $t1, $s3, -1
    addu $t2, $t2, $t1
    sb   $zero, 0($t2)

    beq  $t4, $s4, ica_yes

ica_no:
    li   $v0, 0
    j    ica_done

ica_yes:
    li   $v0, 1

ica_done:
    lw   $s0, 0($sp)
    lw   $s1, 4($sp)
    lw   $s2, 8($sp)
    lw   $s3, 12($sp)
    lw   $s4, 16($sp)
    lw   $s5, 20($sp)
    lw   $ra, 24($sp)
    addiu $sp, $sp, 32
    jr   $ra


# ============================================================================
# PRINT CAPTURE MOVES
# Prints all legal 1st-hop capture landing squares from $a0 for player $a1.
# In International mode, includes all Flying King landing squares along each
# diagonal and filters to those achieving the maximum capture count.
#
# Input:  $a0 = square (1..num_squares), $a1 = player (1=Red, 3=Black)
# Output: $v0 = count of capture destinations printed
# ============================================================================
.globl print_capture_moves
print_capture_moves:
    addiu $sp, $sp, -40
    sw   $s0, 0($sp)
    sw   $s1, 4($sp)
    sw   $s2, 8($sp)
    sw   $s3, 12($sp)
    sw   $s4, 16($sp)
    sw   $s5, 20($sp)
    sw   $s6, 24($sp)
    sw   $s7, 28($sp)
    sw   $ra, 32($sp)
    # 36($sp) = is_flying_king

    move $s0, $a0               # start sq
    move $s1, $a1               # player
    li   $s5, 0                 # count printed

    move $a0, $s0
    jal  square_to_coord
    bltz $v0, pcm_done
    move $s2, $v0               # row
    move $s3, $v1               # col

    # Determine if Flying King
    li   $t5, 0
    la   $t0, ruleset
    lw   $t0, 0($t0)
    beq  $t0, $zero, pcm_store_fk
    la   $t0, board
    addiu $t1, $s0, -1
    addu $t0, $t0, $t1
    lbu  $t2, 0($t0)
    li   $t3, 2
    beq  $t2, $t3, pcm_set_fk
    li   $t3, 4
    beq  $t2, $t3, pcm_set_fk
    j    pcm_store_fk
pcm_set_fk:
    li   $t5, 1
pcm_store_fk:
    sw   $t5, 36($sp)

    li   $s4, 0                 # dir index 0..3

pcm_dir_loop:
    slti $t0, $s4, 4
    beq  $t0, $zero, pcm_done

    li   $s7, 2                 # step k = 2

pcm_step_loop:
    sll  $t1, $s4, 2
    la   $t2, cap_unit_dr
    addu $t2, $t2, $t1
    lw   $t3, 0($t2)
    la   $t2, cap_unit_dc
    addu $t2, $t2, $t1
    lw   $t4, 0($t2)

    mul  $t3, $t3, $s7
    mul  $t4, $t4, $s7
    addu $a0, $s2, $t3
    addu $a1, $s3, $t4
    jal  coord_to_square
    bltz $v0, pcm_next_dir      # Off board -> end ray

    move $s6, $v0               # candidate landing square
    move $a0, $s0
    move $a1, $s6
    move $a2, $s1
    jal  is_capture_allowed
    beq  $v0, $zero, pcm_next_step

    beq  $s5, $zero, pcm_print_num
    li   $a0, 32                # ' '
    li   $v0, 11
    syscall

pcm_print_num:
    move $a0, $s6
    li   $v0, 1
    syscall
    addiu $s5, $s5, 1

pcm_next_step:
    lw   $t5, 36($sp)
    beq  $t5, $zero, pcm_next_dir
    addiu $s7, $s7, 1
    j    pcm_step_loop

pcm_next_dir:
    addiu $s4, $s4, 1
    j    pcm_dir_loop

pcm_done:
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
    addiu $sp, $sp, 40
    jr   $ra


# ============================================================================
# PRINT CAPTURE PATHS
# Prints every complete legal capture chain starting from square $a0 for
# player $a1 (e.g. "    21x14x7\n"). In International mode, only maximum-length
# capture chains are printed. Read-only (restores board & mask).
#
# Input: $a0 = start square, $a1 = player (1=Red, 3=Black)
# ============================================================================
.globl print_capture_paths
print_capture_paths:
    addiu $sp, $sp, -16
    sw   $s0, 0($sp)
    sw   $s1, 4($sp)
    sw   $ra, 8($sp)

    move $s0, $a0
    move $s1, $a1

    jal  max_capture_from
    beq  $v0, $zero, pcp_top_done

    # Initialize path_buf[0] = start, path_len = 1
    la   $t0, path_buf
    sw   $s0, 0($t0)
    la   $t0, path_len
    li   $t1, 1
    sw   $t1, 0($t0)

    move $a0, $s0
    move $a1, $s1
    move $a2, $v0               # req_rem = max_capture_from(start)
    jal  pcp_dfs

pcp_top_done:
    lw   $s0, 0($sp)
    lw   $s1, 4($sp)
    lw   $ra, 8($sp)
    addiu $sp, $sp, 16
    jr   $ra


# Recursive DFS helper: $a0 = cur_sq, $a1 = player, $a2 = req_rem (Intl max filter)
pcp_dfs:
    addiu $sp, $sp, -56
    sw   $s0, 0($sp)
    sw   $s1, 4($sp)
    sw   $s2, 8($sp)
    sw   $s3, 12($sp)
    sw   $s4, 16($sp)
    sw   $s5, 20($sp)
    sw   $s6, 24($sp)
    sw   $s7, 28($sp)
    sw   $ra, 32($sp)
    sw   $a2, 36($sp)           # req_rem
    # 40($sp) = piece_code
    # 44($sp) = is_flying_king
    # 48($sp) = old_captured_piece
    # 52($sp) = cap_sq

    move $s0, $a0               # cur_sq
    move $s1, $a1               # player

    la   $t0, board
    addiu $t1, $s0, -1
    addu $t0, $t0, $t1
    lbu  $t2, 0($t0)
    sw   $t2, 40($sp)

    # Flying King flag
    li   $t5, 0
    la   $t0, ruleset
    lw   $t0, 0($t0)
    beq  $t0, $zero, pcp_store_fk
    li   $t3, 2
    beq  $t2, $t3, pcp_set_fk
    li   $t3, 4
    beq  $t2, $t3, pcp_set_fk
    j    pcp_store_fk
pcp_set_fk:
    li   $t5, 1
pcp_store_fk:
    sw   $t5, 44($sp)

    move $a0, $s0
    jal  square_to_coord
    move $s2, $v0               # r
    move $s3, $v1               # c

    li   $s4, 0                 # dir 0..3

pcp_dir_loop:
    slti $t0, $s4, 4
    beq  $t0, $zero, pcp_dfs_done

    li   $s5, 2                 # k = 2

pcp_step_loop:
    sll  $t1, $s4, 2
    la   $t2, cap_unit_dr
    addu $t2, $t2, $t1
    lw   $t3, 0($t2)
    la   $t2, cap_unit_dc
    addu $t2, $t2, $t1
    lw   $t4, 0($t2)

    mul  $t3, $t3, $s5
    mul  $t4, $t4, $s5
    addu $a0, $s2, $t3
    addu $a1, $s3, $t4
    jal  coord_to_square
    bltz $v0, pcp_next_dir

    move $s6, $v0               # dest
    move $a0, $s0
    move $a1, $s6
    move $a2, $s1
    jal  find_captured_square
    beq  $v0, $zero, pcp_next_step
    sw   $v0, 52($sp)           # cap_sq
    move $s7, $v0

    # Temporarily apply hop
    lw   $t2, 40($sp)
    la   $t0, board
    addiu $t1, $s0, -1
    addu $t1, $t0, $t1
    sb   $zero, 0($t1)

    addiu $t1, $s6, -1
    addu $t1, $t0, $t1
    sb   $t2, 0($t1)

    addiu $t1, $s7, -1
    addu $t3, $t0, $t1
    lbu  $t4, 0($t3)
    sw   $t4, 48($sp)

    la   $t5, ruleset
    lw   $t5, 0($t5)
    beq  $t5, $zero, pcp_apply_am

    # International: mark captured_mask[cap_sq-1] = 1
    la   $t6, captured_mask
    addu $t6, $t6, $t1
    li   $t7, 1
    sb   $t7, 0($t6)

    # Filter: 1 + max_capture_from(dest) must equal req_rem
    move $a0, $s6
    move $a1, $s1
    jal  max_capture_from
    addiu $t0, $v0, 1
    lw   $t1, 36($sp)
    bne  $t0, $t1, pcp_undo_hop # Skip non-maximum branch

    # Push dest onto path_buf
    la   $t0, path_len
    lw   $t1, 0($t0)
    la   $t2, path_buf
    sll  $t3, $t1, 2
    addu $t2, $t2, $t3
    sw   $s6, 0($t2)
    addiu $t1, $t1, 1
    sw   $t1, 0($t0)

    # If req_rem == 1 -> leaf (print path), else recurse with req_rem - 1
    lw   $t4, 36($sp)
    addiu $t4, $t4, -1
    beq  $t4, $zero, pcp_leaf_print

    move $a0, $s6
    move $a1, $s1
    move $a2, $t4
    jal  pcp_dfs
    j    pcp_pop_and_undo

pcp_apply_am:
    # American: remove captured piece immediately
    sb   $zero, 0($t3)

    # Push dest onto path_buf
    la   $t0, path_len
    lw   $t1, 0($t0)
    la   $t2, path_buf
    sll  $t3, $t1, 2
    addu $t2, $t2, $t3
    sw   $s6, 0($t2)
    addiu $t1, $t1, 1
    sw   $t1, 0($t0)

    # If American pawn reached king-row -> turn ends -> leaf!
    move $a0, $s6
    lw   $a1, 40($sp)
    jal  is_king_row_for_pawn
    bne  $v0, $zero, pcp_leaf_print

    # Check if another capture exists from dest
    move $a0, $s6
    move $a1, $s1
    jal  has_capture_from
    beq  $v0, $zero, pcp_leaf_print

    move $a0, $s6
    move $a1, $s1
    li   $a2, 0                 # Unused in American mode
    jal  pcp_dfs
    j    pcp_pop_and_undo

pcp_leaf_print:
    # Print "    s0xs1x...xsk\n"
    li   $v0, 4
    la   $a0, path_indent_msg
    syscall

    la   $t0, path_len
    lw   $t1, 0($t0)            # len
    la   $t2, path_buf
    li   $t3, 0                 # i = 0

pcp_print_loop:
    beq  $t3, $t1, pcp_print_nl
    beq  $t3, $zero, pcp_print_sq
    li   $a0, 120               # 'x'
    li   $v0, 11
    syscall
pcp_print_sq:
    lw   $a0, 0($t2)
    li   $v0, 1
    syscall
    addiu $t2, $t2, 4
    addiu $t3, $t3, 1
    j    pcp_print_loop

pcp_print_nl:
    li   $a0, 10                # '\n'
    li   $v0, 11
    syscall

pcp_pop_and_undo:
    la   $t0, path_len
    lw   $t1, 0($t0)
    addiu $t1, $t1, -1
    sw   $t1, 0($t0)

pcp_undo_hop:
    lw   $s7, 52($sp)           # cap_sq
    la   $t5, ruleset
    lw   $t5, 0($t5)
    beq  $t5, $zero, pcp_undo_am

    la   $t6, captured_mask
    addiu $t1, $s7, -1
    addu $t6, $t6, $t1
    sb   $zero, 0($t6)
    j    pcp_undo_piece

pcp_undo_am:
    la   $t0, board
    addiu $t1, $s7, -1
    addu $t3, $t0, $t1
    lw   $t4, 48($sp)
    sb   $t4, 0($t3)

pcp_undo_piece:
    la   $t0, board
    lw   $t2, 40($sp)
    addiu $t1, $s0, -1
    addu $t1, $t0, $t1
    sb   $t2, 0($t1)

    addiu $t1, $s6, -1
    addu $t1, $t0, $t1
    sb   $zero, 0($t1)

pcp_next_step:
    lw   $t5, 44($sp)
    beq  $t5, $zero, pcp_next_dir
    addiu $s5, $s5, 1
    j    pcp_step_loop

pcp_next_dir:
    addiu $s4, $s4, 1
    j    pcp_dir_loop

pcp_dfs_done:
    lw   $s0, 0($sp)
    lw   $s1, 4($sp)
    lw   $s2, 8($sp)
    lw   $s3, 12($sp)
    lw   $s4, 16($sp)
    lw   $s5, 20($sp)
    lw   $s6, 24($sp)
    lw   $s7, 28($sp)
    lw   $ra, 32($sp)
    addiu $sp, $sp, 56
    jr   $ra


# ============================================================================
# PRINT MANDATORY CAPTURE PIECES
# Prints all starting squares (1..num_squares) of player $a0 that can capture.
# In International mode, only pieces achieving the global maximum capture
# count are printed.
#
# Input:  $a0 = player (1=Red, 3=Black)
# Output: $v0 = count of pieces printed
# ============================================================================
.globl print_mandatory_capture_pieces
print_mandatory_capture_pieces:
    addiu $sp, $sp, -24
    sw   $s0, 0($sp)
    sw   $s1, 4($sp)
    sw   $s2, 8($sp)
    sw   $s3, 12($sp)
    sw   $s4, 16($sp)
    sw   $ra, 20($sp)

    move $s0, $a0               # player
    li   $s1, 1                 # sq = 1..num_squares
    li   $s2, 0                 # count printed
    la   $t0, num_squares
    lw   $s3, 0($t0)

    # If International mode, compute global max capture count into $s4
    li   $s4, 0
    la   $t0, ruleset
    lw   $t0, 0($t0)
    beq  $t0, $zero, pmp_loop
    move $a0, $s0
    jal  max_capture_for_player
    move $s4, $v0               # $s4 = global_max (must be >= 1 to print)

pmp_loop:
    slt  $t0, $s3, $s1
    bne  $t0, $zero, pmp_done

    la   $t0, ruleset
    lw   $t0, 0($t0)
    bne  $t0, $zero, pmp_check_intl

    move $a0, $s1
    move $a1, $s0
    jal  has_capture_from
    beq  $v0, $zero, pmp_next
    j    pmp_print_item

pmp_check_intl:
    beq  $s4, $zero, pmp_done
    move $a0, $s1
    move $a1, $s0
    jal  max_capture_from
    bne  $v0, $s4, pmp_next

pmp_print_item:
    beq  $s2, $zero, pmp_print_sq
    li   $a0, 32                # ' '
    li   $v0, 11
    syscall

pmp_print_sq:
    move $a0, $s1
    li   $v0, 1
    syscall
    addiu $s2, $s2, 1

pmp_next:
    addiu $s1, $s1, 1
    j    pmp_loop

pmp_done:
    move $v0, $s2
    lw   $s0, 0($sp)
    lw   $s1, 4($sp)
    lw   $s2, 8($sp)
    lw   $s3, 12($sp)
    lw   $s4, 16($sp)
    lw   $ra, 20($sp)
    addiu $sp, $sp, 24
    jr   $ra


# ============================================================================
# CHAIN CAPTURE
# Continues mandatory multi-jump captures from square $a0.
# Shows updated board, all legal next landing squares, and full remaining
# capture paths when multiple hops remain.
#
# Input:  $a0 = current square of the capturing piece
# Output: $v0 = 1 if chain ends normally, 0 if invalid state
#         $v1 = final landing square of the capturing piece
# ============================================================================
.globl chain_capture
chain_capture:
    addiu $sp, $sp, -24
    sw   $s0, 0($sp)
    sw   $s1, 4($sp)
    sw   $s2, 8($sp)
    sw   $s3, 12($sp)
    sw   $ra, 16($sp)

    move $s0, $a0               # Current square

    la   $t4, num_squares
    lw   $t4, 0($t4)
    slti $t0, $s0, 1
    bne  $t0, $zero, chain_invalid_state
    slt  $t0, $t4, $s0
    bne  $t0, $zero, chain_invalid_state

    la   $t0, current_player
    lw   $s1, 0($t0)

    li   $t0, 1
    beq  $s1, $t0, chain_check_next
    li   $t0, 3
    bne  $s1, $t0, chain_invalid_state

chain_check_next:
    move $a0, $s0
    jal  check_capture
    beq  $v0, $zero, chain_finished

    jal  print_board

    li   $v0, 4
    la   $a0, chain_avail_msg
    syscall

    move $a0, $s0
    move $a1, $s1
    jal  print_capture_moves

    li   $a0, 10                # '\n'
    li   $v0, 11
    syscall

    # If remaining chain has 2+ hops, also preview full remaining capture paths
    move $a0, $s0
    move $a1, $s1
    jal  max_capture_from
    slti $t0, $v0, 2
    bne  $t0, $zero, chain_request_input

    li   $v0, 4
    la   $a0, chain_paths_msg
    syscall
    move $a0, $s0
    move $a1, $s1
    jal  print_capture_paths

chain_request_input:
    li   $v0, 4
    la   $a0, chain_prompt_msg
    syscall

    li   $v0, 5
    syscall
    move $s2, $v0               # Entered landing square

    # Validate capture (enforces max-capture rule in International mode)
    move $a0, $s0
    move $a1, $s2
    move $a2, $s1
    jal  is_capture_allowed
    beq  $v0, $zero, chain_invalid_input

    move $a0, $s0
    move $a1, $s2
    jal  apply_capture
    beq  $v0, $zero, chain_invalid_input

    move $a0, $s0
    move $a1, $s2
    move $a2, $s1
    jal  print_capture_feedback

    move $s0, $s2               # Update current square

    # Promotion check:
    #   - American (ruleset == 0): promote immediately; if promoted, turn ENDS!
    #   - International (ruleset == 1): do NOT promote mid-chain (deferred to turn end)
    la   $t0, ruleset
    lw   $t0, 0($t0)
    bne  $t0, $zero, chain_check_next

    la   $t0, board
    addiu $t1, $s0, -1
    addu $t0, $t0, $t1
    lbu  $s3, 0($t0)            # Piece before promotion

    move $a0, $s0
    jal  check_promotion

    la   $t0, board
    addiu $t1, $s0, -1
    addu $t0, $t0, $t1
    lbu  $t2, 0($t0)            # Piece after promotion
    beq  $t2, $s3, chain_check_next

    # Pawn was promoted to King on king-row -> American rule: turn ends immediately!
    li   $v0, 4
    la   $a0, chain_promo_pre_msg
    syscall
    move $a0, $s0
    li   $v0, 1
    syscall
    li   $v0, 4
    la   $a0, chain_promo_post_msg
    syscall
    j    chain_finished

chain_invalid_input:
    li   $v0, 4
    la   $a0, chain_invalid_msg
    syscall
    j    chain_request_input

chain_finished:
    li   $v0, 4
    la   $a0, chain_finished_msg
    syscall
    li   $v0, 1
    move $v1, $s0               # Return final square in $v1
    j    chain_done

chain_invalid_state:
    li   $v0, 0
    move $v1, $s0

chain_done:
    lw   $s0, 0($sp)
    lw   $s1, 4($sp)
    lw   $s2, 8($sp)
    lw   $s3, 12($sp)
    lw   $ra, 16($sp)
    addiu $sp, $sp, 24
    jr   $ra


# ============================================================================
# PRINT CAPTURE FEEDBACK
# Input: $a0 = start square, $a1 = dest square, $a2 = capturing player (1 or 3)
# ============================================================================
.globl print_capture_feedback
print_capture_feedback:
    move $t0, $a0
    move $t1, $a1

    li   $t2, 3
    beq  $a2, $t2, pcf_cap_red

    la   $a0, cap_fb_black_msg
    j    pcf_print_pre

pcf_cap_red:
    la   $a0, cap_fb_red_msg

pcf_print_pre:
    li   $v0, 4
    syscall

    move $a0, $t0
    li   $v0, 1
    syscall

    li   $a0, 120               # 'x'
    li   $v0, 11
    syscall

    move $a0, $t1
    li   $v0, 1
    syscall

    la   $a0, cap_fb_close_msg
    li   $v0, 4
    syscall
    jr   $ra
