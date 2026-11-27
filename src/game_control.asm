# ============================================================================
# GAME CONTROL HELPERS
# Owner: Member B
# main.asm owns the entry point and overall game loop.
# ============================================================================

.data
gc_choose_prompt:     .asciiz "\nPlayer 1, choose your side:\n  1. Black (b / B) - moves first\n  2. Red   (r / R) - moves second\nEnter choice (1 or 2): "
gc_choose_invalid:    .asciiz "Invalid choice! Please enter 1 for Black or 2 for Red.\n"
gc_p1_is_black_msg:   .asciiz "Player 1 is BLACK (b/B). Player 2 is RED (r/R). Black moves first!\n"
gc_p1_is_red_msg:     .asciiz "Player 1 is RED (r/R). Player 2 is BLACK (b/B). Black moves first!\n"

gc_p1_black_turn_msg: .asciiz "\n=== Player 1's Turn: BLACK (b / B) ===\n"
gc_p2_black_turn_msg: .asciiz "\n=== Player 2's Turn: BLACK (b / B) ===\n"
gc_p1_red_turn_msg:   .asciiz "\n=== Player 1's Turn: RED (r / R) ===\n"
gc_p2_red_turn_msg:   .asciiz "\n=== Player 2's Turn: RED (r / R) ===\n"

gc_prompt_start_32:   .asciiz "Enter starting square (1-32): "
gc_prompt_start_50:   .asciiz "Enter starting square (1-50): "
gc_prompt_dest_32:    .asciiz "Enter destination square (1-32): "
gc_prompt_dest_50:    .asciiz "Enter destination square (1-50): "

gc_p1_black_wins_msg: .asciiz "\n==========================================\n   GAME OVER: PLAYER 1 (BLACK) WINS!\n==========================================\n"
gc_p2_black_wins_msg: .asciiz "\n==========================================\n   GAME OVER: PLAYER 2 (BLACK) WINS!\n==========================================\n"
gc_p1_red_wins_msg:   .asciiz "\n==========================================\n   GAME OVER: PLAYER 1 (RED) WINS!\n==========================================\n"
gc_p2_red_wins_msg:   .asciiz "\n==========================================\n   GAME OVER: PLAYER 2 (RED) WINS!\n==========================================\n"

gc_mode_prompt:       .asciiz "\nSelect Checkers ruleset:\n  1. American / English Checkers (8x8, 12 pieces/side, Official mandatory capture)\n  2. International Checkers      (10x10, 20 pieces/side, Flying Kings, Backward & Max capture)\n  3. American / English Casual   (8x8, optional initial capture; chain capture mandatory)\nEnter choice (1, 2, or 3): "
gc_mode_invalid:      .asciiz "Invalid choice! Please enter 1, 2, or 3.\n"
gc_mode_official_msg: .asciiz "Mode: American / English Checkers (8x8, Official Mandatory Capture ON).\n"
gc_mode_intl_msg:     .asciiz "Mode: International Checkers (10x10, Flying Kings, Backward Pawn Capture, Max Capture ON).\n"
gc_mode_casual_msg:   .asciiz "Mode: American / English Casual (8x8, Mandatory Initial Capture OFF).\n"

gc_prompt_dest_opt32: .asciiz "Enter destination square (1-32, or 0 to pick another piece): "
gc_prompt_dest_opt50: .asciiz "Enter destination square (1-50, or 0 to pick another piece): "

gc_piece_red_pawn:    .asciiz "Red pawn"
gc_piece_red_king:    .asciiz "Red King"
gc_piece_black_pawn:  .asciiz "Black pawn"
gc_piece_black_king:  .asciiz "Black King"

gc_move_fb_pre:       .asciiz "Move played: "
gc_promo_red_pre:     .asciiz "Promoted to Red King at square "
gc_promo_black_pre:   .asciiz "Promoted to Black King at square "
gc_promo_post:        .asciiz "!\n"
gc_win_elim_msg:      .asciiz "\nAll opponent pieces have been captured!\n"
gc_win_trap_msg:      .asciiz "\nOpponent has no legal moves remaining (trapped)!\n"

.text

# ============================================================================
# CHECK WINNER
# Scans all playable squares (1..num_squares) to check if player $a0 has 0 pieces.
# Input:  $a0 = player to check (1 = Red, 3 = Black)
# Output: $v0 = 1 (0 pieces), 0 (has pieces), -1 (invalid player)
# ============================================================================
.globl check_winner
check_winner:
    li   $t0, 1
    beq  $a0, $t0, cw_check_red

    li   $t0, 3
    beq  $a0, $t0, cw_check_black

    li   $v0, -1
    jr   $ra

cw_check_red:
    li   $t5, 1
    li   $t6, 2
    j    cw_start_scan

cw_check_black:
    li   $t5, 3
    li   $t6, 4

cw_start_scan:
    la   $t1, board
    li   $t2, 0
    la   $t3, num_squares
    lw   $t3, 0($t3)            # 32 (American) or 50 (International)

cw_scan_loop:
    beq  $t2, $t3, cw_no_pieces

    lbu  $t4, 0($t1)
    beq  $t4, $t5, cw_has_piece
    beq  $t4, $t6, cw_has_piece

    addiu $t1, $t1, 1
    addiu $t2, $t2, 1
    j    cw_scan_loop

cw_has_piece:
    li   $v0, 0
    jr   $ra

cw_no_pieces:
    li   $v0, 1
    jr   $ra


# ============================================================================
# CHOOSE PLAYER COLOR
# Prompts Player 1 to pick Black (1) or Red (2) and stores their color code
# (3 = Black, 1 = Red) into shared global player1_color.
# ============================================================================
.globl choose_player_color
choose_player_color:
gc_choose_loop:
    li   $v0, 4
    la   $a0, gc_choose_prompt
    syscall

    li   $v0, 5
    syscall

    li   $t0, 1
    beq  $v0, $t0, gc_pick_black

    li   $t0, 2
    beq  $v0, $t0, gc_pick_red

    li   $v0, 4
    la   $a0, gc_choose_invalid
    syscall
    j    gc_choose_loop

gc_pick_black:
    la   $t0, player1_color
    li   $t1, 3
    sw   $t1, 0($t0)

    li   $v0, 4
    la   $a0, gc_p1_is_black_msg
    syscall
    jr   $ra

gc_pick_red:
    la   $t0, player1_color
    li   $t1, 1
    sw   $t1, 0($t0)

    li   $v0, 4
    la   $a0, gc_p1_is_red_msg
    syscall
    jr   $ra


# ============================================================================
# PRINT TURN BANNER
# ============================================================================
.globl print_turn_banner
print_turn_banner:
    la   $t0, current_player
    lw   $t1, 0($t0)

    la   $t0, player1_color
    lw   $t2, 0($t0)

    li   $t3, 3
    beq  $t1, $t3, gc_print_black

    beq  $t1, $t2, gc_print_p1_red
    la   $a0, gc_p2_red_turn_msg
    j    gc_print_turn_out

gc_print_p1_red:
    la   $a0, gc_p1_red_turn_msg
    j    gc_print_turn_out

gc_print_black:
    beq  $t1, $t2, gc_print_p1_black
    la   $a0, gc_p2_black_turn_msg
    j    gc_print_turn_out

gc_print_p1_black:
    la   $a0, gc_p1_black_turn_msg

gc_print_turn_out:
    li   $v0, 4
    syscall
    jr   $ra


# ============================================================================
# READ PLAYER MOVE (legacy combined helper)
# ============================================================================
.globl read_player_move
read_player_move:
    la   $t3, ruleset
    lw   $t3, 0($t3)
    bne  $t3, $zero, rpm_start_50
    la   $a0, gc_prompt_start_32
    j    rpm_read_start
rpm_start_50:
    la   $a0, gc_prompt_start_50
rpm_read_start:
    li   $v0, 4
    syscall

    li   $v0, 5
    syscall
    move $t0, $v0

    la   $t2, start_square
    sw   $t0, 0($t2)

    bne  $t3, $zero, rpm_dest_50
    la   $a0, gc_prompt_dest_32
    j    rpm_read_dest
rpm_dest_50:
    la   $a0, gc_prompt_dest_50
rpm_read_dest:
    li   $v0, 4
    syscall

    li   $v0, 5
    syscall
    move $t1, $v0

    la   $t2, destination
    sw   $t1, 0($t2)

    move $v0, $t0
    move $v1, $t1
    jr   $ra


# ============================================================================
# SWITCH PLAYER
# Toggles global current_player between 3 (Black) and 1 (Red).
# ============================================================================
.globl switch_player
switch_player:
    la   $t0, current_player
    lw   $t1, 0($t0)

    li   $t2, 3
    beq  $t1, $t2, gc_set_red

    li   $t1, 3
    j    gc_store_player

gc_set_red:
    li   $t1, 1

gc_store_player:
    sw   $t1, 0($t0)
    jr   $ra


# ============================================================================
# ANNOUNCE WINNER
# ============================================================================
.globl announce_winner
announce_winner:
    la   $t0, game_over
    li   $t1, 1
    sw   $t1, 0($t0)

    la   $t0, player1_color
    lw   $t1, 0($t0)

    li   $t2, 3
    beq  $a0, $t2, gc_black_won

    beq  $a0, $t1, gc_p1_red_won
    la   $a0, gc_p2_red_wins_msg
    j    gc_print_winner

gc_p1_red_won:
    la   $a0, gc_p1_red_wins_msg
    j    gc_print_winner

gc_black_won:
    beq  $a0, $t1, gc_p1_black_won
    la   $a0, gc_p2_black_wins_msg
    j    gc_print_winner

gc_p1_black_won:
    la   $a0, gc_p1_black_wins_msg

gc_print_winner:
    li   $v0, 4
    syscall
    jr   $ra


# ============================================================================
# CHOOSE GAME MODE
# Prompts user to select:
#   1. American / English Checkers (ruleset = 0, mandatory_capture = 1, 8x8)
#   2. International Checkers      (ruleset = 1, mandatory_capture = 1, 10x10)
#   3. American / English Casual   (ruleset = 0, mandatory_capture = 0, 8x8)
# ============================================================================
.globl choose_game_mode
choose_game_mode:
gc_mode_loop:
    li   $v0, 4
    la   $a0, gc_mode_prompt
    syscall

    li   $v0, 5
    syscall

    li   $t0, 1
    beq  $v0, $t0, gc_mode_set_official

    li   $t0, 2
    beq  $v0, $t0, gc_mode_set_intl

    li   $t0, 3
    beq  $v0, $t0, gc_mode_set_casual

    li   $v0, 4
    la   $a0, gc_mode_invalid
    syscall
    j    gc_mode_loop

gc_mode_set_official:
    la   $t0, ruleset
    sw   $zero, 0($t0)
    la   $t0, mandatory_capture
    li   $t1, 1
    sw   $t1, 0($t0)
    li   $v0, 4
    la   $a0, gc_mode_official_msg
    syscall
    jr   $ra

gc_mode_set_intl:
    la   $t0, ruleset
    li   $t1, 1
    sw   $t1, 0($t0)
    la   $t0, mandatory_capture
    sw   $t1, 0($t0)
    li   $v0, 4
    la   $a0, gc_mode_intl_msg
    syscall
    jr   $ra

gc_mode_set_casual:
    la   $t0, ruleset
    sw   $zero, 0($t0)
    la   $t0, mandatory_capture
    sw   $zero, 0($t0)
    li   $v0, 4
    la   $a0, gc_mode_casual_msg
    syscall
    jr   $ra


# ============================================================================
# READ START SQUARE / READ DEST SQUARE
# ============================================================================
.globl read_start_square
read_start_square:
    la   $t0, ruleset
    lw   $t0, 0($t0)
    bne  $t0, $zero, rss_50
    la   $a0, gc_prompt_start_32
    j    rss_prompt
rss_50:
    la   $a0, gc_prompt_start_50
rss_prompt:
    li   $v0, 4
    syscall

    li   $v0, 5
    syscall

    la   $t0, start_square
    sw   $v0, 0($t0)
    jr   $ra

.globl read_dest_square
read_dest_square:
    la   $t0, ruleset
    lw   $t0, 0($t0)
    bne  $t0, $zero, rds_50
    la   $a0, gc_prompt_dest_opt32
    j    rds_prompt
rds_50:
    la   $a0, gc_prompt_dest_opt50
rds_prompt:
    li   $v0, 4
    syscall

    li   $v0, 5
    syscall

    la   $t0, destination
    sw   $v0, 0($t0)
    jr   $ra


# ============================================================================
# PRINT PIECE NAME
# ============================================================================
.globl print_piece_name
print_piece_name:
    li   $t0, 1
    beq  $a0, $t0, gc_pn_red_pawn
    li   $t0, 2
    beq  $a0, $t0, gc_pn_red_king
    li   $t0, 3
    beq  $a0, $t0, gc_pn_black_pawn
    la   $a0, gc_piece_black_king
    j    gc_pn_out

gc_pn_red_pawn:
    la   $a0, gc_piece_red_pawn
    j    gc_pn_out

gc_pn_red_king:
    la   $a0, gc_piece_red_king
    j    gc_pn_out

gc_pn_black_pawn:
    la   $a0, gc_piece_black_pawn

gc_pn_out:
    li   $v0, 4
    syscall
    jr   $ra


# ============================================================================
# PRINT MOVE FEEDBACK
# ============================================================================
.globl print_move_feedback
print_move_feedback:
    move $t0, $a0
    move $t1, $a1

    li   $v0, 4
    la   $a0, gc_move_fb_pre
    syscall

    move $a0, $t0
    li   $v0, 1
    syscall

    li   $a0, 45                 # '-'
    li   $v0, 11
    syscall

    move $a0, $t1
    li   $v0, 1
    syscall

    li   $a0, 10                 # '\n'
    li   $v0, 11
    syscall
    jr   $ra


# ============================================================================
# PRINT PROMOTION FEEDBACK
# ============================================================================
.globl print_promotion_feedback
print_promotion_feedback:
    move $t0, $a0

    li   $t1, 2
    beq  $a1, $t1, gc_pf_red
    la   $a0, gc_promo_black_pre
    j    gc_pf_print

gc_pf_red:
    la   $a0, gc_promo_red_pre

gc_pf_print:
    li   $v0, 4
    syscall

    move $a0, $t0
    li   $v0, 1
    syscall

    li   $v0, 4
    la   $a0, gc_promo_post
    syscall
    jr   $ra


# ============================================================================
# PRINT WIN REASON
# ============================================================================
.globl print_win_reason
print_win_reason:
    beq  $a0, $zero, gc_wr_elim
    la   $a0, gc_win_trap_msg
    j    gc_wr_out

gc_wr_elim:
    la   $a0, gc_win_elim_msg

gc_wr_out:
    li   $v0, 4
    syscall
    jr   $ra
