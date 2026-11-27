# ============================================================================
# GAME CONTROL HELPERS
# Owner: Member B
# main.asm owns the entry point and overall game loop.
# ============================================================================


# ============================================================================
# CHECK WINNER
# Owner: Member B
#
# Input:
#   $a0 = player to check
#         1 = Red
#         3 = Black
#
# Output:
#   $v0 = 1  -> Player has no remaining pieces
#   $v0 = 0  -> Player still has at least one piece
#   $v0 = -1 -> Invalid player
#
# Board encoding:
#   0 = Empty
#   1 = Red pawn
#   2 = Red king
#   3 = Black pawn
#   4 = Black king
#
# This procedure does NOT modify the board.
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

gc_prompt_start:      .asciiz "Enter starting square (1-32): "
gc_prompt_dest:       .asciiz "Enter destination square (1-32): "

gc_p1_black_wins_msg: .asciiz "\n==========================================\n   GAME OVER: PLAYER 1 (BLACK) WINS!\n==========================================\n"
gc_p2_black_wins_msg: .asciiz "\n==========================================\n   GAME OVER: PLAYER 2 (BLACK) WINS!\n==========================================\n"
gc_p1_red_wins_msg:   .asciiz "\n==========================================\n   GAME OVER: PLAYER 1 (RED) WINS!\n==========================================\n"
gc_p2_red_wins_msg:   .asciiz "\n==========================================\n   GAME OVER: PLAYER 2 (RED) WINS!\n==========================================\n"

gc_mode_prompt:       .asciiz "\nSelect ruleset:\n  1. Official English Checkers (Mandatory initial capture)\n  2. Casual Mode (Initial capture optional; chain capture still mandatory)\nEnter choice (1 or 2): "
gc_mode_invalid:      .asciiz "Invalid choice! Please enter 1 or 2.\n"
gc_mode_official_msg: .asciiz "Mode: Official English Checkers (Mandatory Capture ON).\n"
gc_mode_casual_msg:   .asciiz "Mode: Casual Checkers (Mandatory Initial Capture OFF).\n"

gc_prompt_dest_opt:   .asciiz "Enter destination square (1-32, or 0 to pick another piece): "

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
.globl check_winner

check_winner:

    # ------------------------------------------------
    # 1. Determine which player's pieces to search for
    # ------------------------------------------------

    li   $t0, 1
    beq  $a0, $t0, cw_check_red

    li   $t0, 3
    beq  $a0, $t0, cw_check_black

    # Invalid player argument

    li   $v0, -1
    jr   $ra


    # ------------------------------------------------
    # 2. Search for Red pieces
    #
    # Red pawn = 1
    # Red king = 2
    # ------------------------------------------------

cw_check_red:

    li   $t5, 1
    li   $t6, 2

    j cw_start_scan


    # ------------------------------------------------
    # 3. Search for Black pieces
    #
    # Black pawn = 3
    # Black king = 4
    # ------------------------------------------------

cw_check_black:

    li   $t5, 3
    li   $t6, 4


    # ------------------------------------------------
    # 4. Scan all 32 playable squares
    # ------------------------------------------------

cw_start_scan:

    la   $t1, board

    li   $t2, 0              # Array index
    li   $t3, 32             # Number of squares


cw_scan_loop:

    # Stop after checking all 32 squares

    beq  $t2, $t3, cw_no_pieces

    # Load current piece

    lbu  $t4, 0($t1)

    # Check for player's pawn

    beq  $t4, $t5, cw_has_piece

    # Check for player's king

    beq  $t4, $t6, cw_has_piece

    # Move to next array position

    addiu $t1, $t1, 1
    addiu $t2, $t2, 1

    j cw_scan_loop


    # ------------------------------------------------
    # 5. At least one piece found
    # ------------------------------------------------

cw_has_piece:

    li $v0, 0

    jr $ra


    # ------------------------------------------------
    # 6. No pieces found after scanning the entire board
    # ------------------------------------------------

cw_no_pieces:

    li $v0, 1

    jr $ra

# ============================================================================
# CHOOSE PLAYER COLOR
# Prompts Player 1 to pick Black (1) or Red (2) and stores their color code
# (3 = Black, 1 = Red) into shared global player1_color.
# Black still moves first per English Checkers rules.
# ============================================================================
.globl choose_player_color
choose_player_color:
gc_choose_loop:
    li   $v0, 4
    la   $a0, gc_choose_prompt
    syscall

    li   $v0, 5                  # Read integer choice (1 or 2)
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
    li   $t1, 3                  # Player 1 = Black (3), Player 2 = Red (1)
    sw   $t1, 0($t0)

    li   $v0, 4
    la   $a0, gc_p1_is_black_msg
    syscall
    jr   $ra

gc_pick_red:
    la   $t0, player1_color
    li   $t1, 1                  # Player 1 = Red (1), Player 2 = Black (3)
    sw   $t1, 0($t0)

    li   $v0, 4
    la   $a0, gc_p1_is_red_msg
    syscall
    jr   $ra

# ============================================================================
# PRINT TURN BANNER
# Reads globals current_player and player1_color and prints whose turn it is.
# ============================================================================
.globl print_turn_banner
print_turn_banner:
    la   $t0, current_player     # $t0 = address of shared global current_player
    lw   $t1, 0($t0)             # $t1 = active color (3 = Black, 1 = Red)

    la   $t0, player1_color
    lw   $t2, 0($t0)             # $t2 = Player 1's color (3 or 1)

    li   $t3, 3                  # Check if active color is Black (3)
    beq  $t1, $t3, gc_print_black

    # Active color is Red (1)
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
    li   $v0, 4                  # Syscall 4 = print_string
    syscall
    jr   $ra                     # Leaf procedure (no jal) -> no stack needed

# ============================================================================
# READ PLAYER MOVE
# Prompts user for start and destination squares, stores them in shared
# globals (start_square, destination), and also returns them in ($v0, $v1).
# Output: $v0 = start_square, $v1 = destination
# ============================================================================
.globl read_player_move
read_player_move:
    # 1. Prompt and read starting square
    li   $v0, 4                  # Syscall 4: print_string
    la   $a0, gc_prompt_start
    syscall

    li   $v0, 5                  # Syscall 5: read_int -> result lands in $v0
    syscall
    move $t0, $v0                # Save start in $t0 (next syscall overwrites $v0)

    la   $t2, start_square       # Store into shared global start_square
    sw   $t0, 0($t2)             # (Required by plan.md Section 3.2)

    # 2. Prompt and read destination square
    li   $v0, 4
    la   $a0, gc_prompt_dest
    syscall

    li   $v0, 5                  # Syscall 5: read_int -> result lands in $v0
    syscall
    move $t1, $v0                # Save destination in $t1

    la   $t2, destination        # Store into shared global destination
    sw   $t1, 0($t2)

    # 3. Return both values to caller
    move $v0, $t0                # $v0 = start_square
    move $v1, $t1                # $v1 = destination
    jr   $ra

# ============================================================================
# SWITCH PLAYER
# Toggles global current_player between 3 (Black) and 1 (Red).
# ============================================================================
.globl switch_player
switch_player:
    la   $t0, current_player     # $t0 = address of current_player
    lw   $t1, 0($t0)             # $t1 = current value (1 or 3)

    li   $t2, 3                  # Is it currently Black (3)?
    beq  $t1, $t2, gc_set_red

    li   $t1, 3                  # Otherwise it was Red (1) -> switch to Black (3)
    j    gc_store_player

gc_set_red:
    li   $t1, 1                  # Switch to Red (1)

gc_store_player:
    sw   $t1, 0($t0)             # Write updated player back to memory
    jr   $ra

# ============================================================================
# ANNOUNCE WINNER
# Input:  $a0 = winning color (1 = Red, 3 = Black)
# Effect: Sets global game_over = 1 and prints the winner announcement
#         including Player 1 / Player 2 identity from player1_color.
# ============================================================================
.globl announce_winner
announce_winner:
    # 1. Mark game_over = 1 in shared global state
    la   $t0, game_over
    li   $t1, 1
    sw   $t1, 0($t0)

    # 2. Load Player 1's color and pick the matching winner message
    la   $t0, player1_color
    lw   $t1, 0($t0)             # $t1 = Player 1's color (1 or 3)

    li   $t2, 3
    beq  $a0, $t2, gc_black_won

    # Winner is Red (1)
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
    li   $v0, 4                  # Syscall 4: print_string
    syscall
    jr   $ra

# ============================================================================
# CHOOSE GAME MODE
# Prompts user to select Official English Checkers (mandatory initial capture)
# or Casual Mode, storing 1 or 0 in shared global mandatory_capture.
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
    beq  $v0, $t0, gc_mode_set_casual

    li   $v0, 4
    la   $a0, gc_mode_invalid
    syscall
    j    gc_mode_loop

gc_mode_set_official:
    la   $t0, mandatory_capture
    li   $t1, 1
    sw   $t1, 0($t0)
    li   $v0, 4
    la   $a0, gc_mode_official_msg
    syscall
    jr   $ra

gc_mode_set_casual:
    la   $t0, mandatory_capture
    sw   $zero, 0($t0)
    li   $v0, 4
    la   $a0, gc_mode_casual_msg
    syscall
    jr   $ra

# ============================================================================
# READ START SQUARE / READ DEST SQUARE
# Two-step input helpers so the player sees legal moves after selecting a piece.
# ============================================================================
.globl read_start_square
read_start_square:
    li   $v0, 4
    la   $a0, gc_prompt_start
    syscall

    li   $v0, 5
    syscall

    la   $t0, start_square
    sw   $v0, 0($t0)
    jr   $ra

.globl read_dest_square
read_dest_square:
    li   $v0, 4
    la   $a0, gc_prompt_dest_opt
    syscall

    li   $v0, 5
    syscall

    la   $t0, destination
    sw   $v0, 0($t0)
    jr   $ra

# ============================================================================
# PRINT PIECE NAME
# Input: $a0 = piece code (1=Red pawn, 2=Red King, 3=Black pawn, 4=Black King)
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
# Prints standard checkers normal-move notation: "Move played: <start>-<dest>\n"
# Input: $a0 = start square, $a1 = destination square
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
# Input: $a0 = square, $a1 = promoted piece code (2 = Red King, 4 = Black King)
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
# Input: $a0 = 0 (all opponent pieces eliminated) or 1 (opponent trapped)
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