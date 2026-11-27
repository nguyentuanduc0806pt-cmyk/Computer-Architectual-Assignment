# ============================================================================
# CO2008 CHECKERS — PROGRAM ENTRY POINT & MAIN GAME LOOP
# Owner: Member B
# MARS 4.5: Open this file with "Assemble all files in directory" enabled.
# Supports both American/English Checkers (8x8) and International Checkers (10x10),
# 180-degree board rotation per turn, and full multi-jump capture previews.
# ============================================================================

.data
main_welcome_msg:       .asciiz "================================================\n           CO2008 CHECKERS (MIPS)\n   American (8x8) & International (10x10)\n     Black (b/B) moves first vs Red (r/R)\n================================================\n"
main_mand_cap_msg:      .asciiz "Mandatory capture! Pieces that can capture: "
main_intl_cap_pre:      .asciiz "Mandatory MAX capture ("
main_intl_cap_mid:      .asciiz " piece(s))! Pieces that can capture: "
main_bad_range_32:      .asciiz "Invalid square! Please enter a number from 1 to 32.\n"
main_bad_range_50:      .asciiz "Invalid square! Please enter a number from 1 to 50.\n"
main_empty_sq_msg:      .asciiz "Square is empty! Please select one of your own pieces.\n"
main_wrong_owner_msg:   .asciiz "That piece belongs to your opponent! Select your own piece.\n"
main_sel_pre_msg:       .asciiz "Selected square "
main_sel_mid_msg:       .asciiz " ("
main_sel_post_msg:      .asciiz ").\n"
main_must_cap_piece:    .asciiz "This piece cannot capture! Choose one of the pieces with a mandatory capture.\n"
main_must_max_piece:    .asciiz "This piece does not achieve the maximum capture! Choose one of the listed pieces.\n"
main_no_moves_msg:      .asciiz "This piece has no legal moves! Please choose another piece.\n"
main_legal_moves_msg:   .asciiz "  Legal moves: "
main_legal_caps_msg:    .asciiz "  Legal captures: "
main_legal_paths_msg:   .asciiz "  Legal capture paths:\n"
main_bad_cap_dest_msg:  .asciiz "Invalid destination! Choose one of the listed capture squares (or 0 to reselect).\n"
main_bad_dest_msg:      .asciiz "Invalid destination! Choose one of the listed legal squares (or 0 to reselect).\n"

.text
.globl main
main:
    # 1. Print welcome banner and configure player sides & ruleset
    li   $v0, 4
    la   $a0, main_welcome_msg
    syscall

    jal  choose_player_color     # Sets player1_color (3 = Black, 1 = Red)
    jal  choose_game_mode        # Sets ruleset (0=American, 1=Intl) & mandatory_capture

    # 2. Initialize board (8x8 or 10x10) and shared game-state globals
    jal  init_board

    la   $t0, current_player
    li   $t1, 3                  # Black moves first
    sw   $t1, 0($t0)

    la   $t0, game_over
    sw   $zero, 0($t0)

    # ------------------------------------------------------------------------
    # OUTER GAME LOOP: runs once per turn until game_over != 0
    # ------------------------------------------------------------------------
main_turn_loop:
    la   $t0, game_over
    lw   $t1, 0($t0)
    bne  $t1, $zero, main_exit

    jal  print_board             # Displays 8x8 or 10x10 board, rotated 180 deg for Red
    jal  print_turn_banner

    la   $t0, current_player
    lw   $s2, 0($t0)             # $s2 = current_player (1 or 3)

    # Determine mandatory capture state ($s4):
    #   0 = no mandatory capture active
    #   >0 = mandatory capture active (in Intl mode, $s4 = required max capture count)
    li   $s4, 0
    la   $t0, mandatory_capture
    lw   $t1, 0($t0)
    beq  $t1, $zero, main_select_piece

    la   $t0, ruleset
    lw   $t1, 0($t0)
    bne  $t1, $zero, main_check_intl_mand

    # American mandatory capture check
    move $a0, $s2
    jal  has_any_capture
    beq  $v0, $zero, main_select_piece

    li   $s4, 1
    li   $v0, 4
    la   $a0, main_mand_cap_msg
    syscall

    move $a0, $s2
    jal  print_mandatory_capture_pieces

    li   $a0, 10
    li   $v0, 11
    syscall
    j    main_select_piece

main_check_intl_mand:
    # International mandatory MAXIMUM capture check
    move $a0, $s2
    jal  max_capture_for_player
    beq  $v0, $zero, main_select_piece

    move $s4, $v0                # $s4 = required global max capture count
    li   $v0, 4
    la   $a0, main_intl_cap_pre
    syscall
    move $a0, $s4
    li   $v0, 1
    syscall
    li   $v0, 4
    la   $a0, main_intl_cap_mid
    syscall

    move $a0, $s2
    jal  print_mandatory_capture_pieces

    li   $a0, 10
    li   $v0, 11
    syscall

    # ------------------------------------------------------------------------
    # STEP 1: SELECT PIECE & DISPLAY ITS LEGAL MOVES / CAPTURE PATHS
    # ------------------------------------------------------------------------
main_select_piece:
    jal  read_start_square
    move $s0, $v0                # $s0 = start_square

    # Validate range 1..num_squares
    la   $t2, num_squares
    lw   $t2, 0($t2)
    slti $t0, $s0, 1
    bne  $t0, $zero, main_err_range
    slt  $t0, $t2, $s0
    bne  $t0, $zero, main_err_range

    # Load piece at start square and verify ownership
    la   $t0, board
    addiu $t1, $s0, -1
    addu $t0, $t0, $t1
    lbu  $s5, 0($t0)             # $s5 = piece code at start

    beq  $s5, $zero, main_err_empty

    li   $t0, 1
    beq  $s2, $t0, main_check_red_own

    li   $t0, 3
    beq  $s5, $t0, main_piece_owned
    li   $t0, 4
    beq  $s5, $t0, main_piece_owned
    j    main_err_owner

main_check_red_own:
    li   $t0, 1
    beq  $s5, $t0, main_piece_owned
    li   $t0, 2
    beq  $s5, $t0, main_piece_owned
    j    main_err_owner

main_piece_owned:
    # Print selected square and piece type
    li   $v0, 4
    la   $a0, main_sel_pre_msg
    syscall
    move $a0, $s0
    li   $v0, 1
    syscall
    li   $v0, 4
    la   $a0, main_sel_mid_msg
    syscall
    move $a0, $s5
    jal  print_piece_name
    li   $v0, 4
    la   $a0, main_sel_post_msg
    syscall

    # Query available captures ($s6 = max_capture_from) and normal moves ($s7)
    move $a0, $s0
    move $a1, $s2
    jal  max_capture_from
    move $s6, $v0                # $s6 = max capture count from this piece (0 if none)

    move $a0, $s0
    move $a1, $s2
    jal  has_normal_move
    move $s7, $v0                # $s7 = 1 if piece has a normal move

    # If mandatory capture is active this turn, only legal capturing pieces allowed
    bne  $s4, $zero, main_show_mandatory_caps

    # Casual / no mandatory capture: ensure piece has at least one legal move
    or   $t0, $s6, $s7
    beq  $t0, $zero, main_err_no_moves

    beq  $s7, $zero, main_show_opt_caps
    li   $v0, 4
    la   $a0, main_legal_moves_msg
    syscall
    move $a0, $s0
    move $a1, $s2
    jal  print_normal_moves
    li   $a0, 10
    li   $v0, 11
    syscall

main_show_opt_caps:
    beq  $s6, $zero, main_select_dest
    li   $v0, 4
    la   $a0, main_legal_caps_msg
    syscall
    move $a0, $s0
    move $a1, $s2
    jal  print_capture_moves
    li   $a0, 10
    li   $v0, 11
    syscall

    # Preview full multi-jump chains whenever 2+ captures are possible
    slti $t0, $s6, 2
    bne  $t0, $zero, main_select_dest
    li   $v0, 4
    la   $a0, main_legal_paths_msg
    syscall
    move $a0, $s0
    move $a1, $s2
    jal  print_capture_paths
    j    main_select_dest

main_show_mandatory_caps:
    beq  $s6, $zero, main_err_must_cap

    # In International mode, piece MUST achieve the global maximum capture count ($s4)
    la   $t0, ruleset
    lw   $t0, 0($t0)
    beq  $t0, $zero, main_print_mand_caps
    bne  $s6, $s4, main_err_must_max

main_print_mand_caps:
    li   $v0, 4
    la   $a0, main_legal_caps_msg
    syscall
    move $a0, $s0
    move $a1, $s2
    jal  print_capture_moves
    li   $a0, 10
    li   $v0, 11
    syscall

    # Preview full multi-jump chains whenever 2+ captures are possible
    slti $t0, $s6, 2
    bne  $t0, $zero, main_select_dest
    li   $v0, 4
    la   $a0, main_legal_paths_msg
    syscall
    move $a0, $s0
    move $a1, $s2
    jal  print_capture_paths
    j    main_select_dest

main_err_range:
    la   $t0, ruleset
    lw   $t0, 0($t0)
    bne  $t0, $zero, main_err_range50
    la   $a0, main_bad_range_32
    j    main_err_range_out
main_err_range50:
    la   $a0, main_bad_range_50
main_err_range_out:
    li   $v0, 4
    syscall
    j    main_select_piece

main_err_empty:
    li   $v0, 4
    la   $a0, main_empty_sq_msg
    syscall
    j    main_select_piece

main_err_owner:
    li   $v0, 4
    la   $a0, main_wrong_owner_msg
    syscall
    j    main_select_piece

main_err_must_cap:
    li   $v0, 4
    la   $a0, main_must_cap_piece
    syscall
    j    main_select_piece

main_err_must_max:
    li   $v0, 4
    la   $a0, main_must_max_piece
    syscall
    j    main_select_piece

main_err_no_moves:
    li   $v0, 4
    la   $a0, main_no_moves_msg
    syscall
    j    main_select_piece

    # ------------------------------------------------------------------------
    # STEP 2: SELECT DESTINATION SQUARE (0 = RESELECT ANOTHER PIECE)
    # ------------------------------------------------------------------------
main_select_dest:
    jal  read_dest_square
    move $s1, $v0                # $s1 = destination

    beq  $s1, $zero, main_select_piece

    bne  $s4, $zero, main_try_mandatory_cap

    # ---- Attempt 1: Normal diagonal move ----
    move $a0, $s0
    move $a1, $s1
    move $a2, $s2
    jal  validate_normal_move
    bne  $v0, $zero, main_do_normal_move

    # ---- Attempt 2: Capture move ----
    move $a0, $s0
    move $a1, $s1
    move $a2, $s2
    jal  is_capture_allowed
    bne  $v0, $zero, main_do_capture

    li   $v0, 4
    la   $a0, main_bad_dest_msg
    syscall
    j    main_select_dest

main_try_mandatory_cap:
    move $a0, $s0
    move $a1, $s1
    move $a2, $s2
    jal  is_capture_allowed
    bne  $v0, $zero, main_do_capture

    li   $v0, 4
    la   $a0, main_bad_cap_dest_msg
    syscall
    j    main_select_dest

    # ------------------------------------------------------------------------
    # EXECUTE NORMAL MOVE + FEEDBACK + PROMOTION
    # ------------------------------------------------------------------------
main_do_normal_move:
    move $a0, $s0
    move $a1, $s1
    jal  apply_normal_move

    move $a0, $s0
    move $a1, $s1
    jal  print_move_feedback

    la   $t0, board
    addiu $t1, $s1, -1
    addu $t0, $t0, $t1
    lbu  $s5, 0($t0)

    move $a0, $s1
    jal  check_promotion

    la   $t0, board
    addiu $t1, $s1, -1
    addu $t0, $t0, $t1
    lbu  $t2, 0($t0)
    beq  $t2, $s5, main_after_move

    move $a0, $s1
    move $a1, $t2
    jal  print_promotion_feedback
    j    main_after_move

    # ------------------------------------------------------------------------
    # EXECUTE CAPTURE + FEEDBACK + RULESET-SPECIFIC PROMOTION & CHAIN
    # ------------------------------------------------------------------------
main_do_capture:
    # Mark active chain so International mode defers captured-piece removal
    la   $t0, in_capture_chain
    li   $t1, 1
    sw   $t1, 0($t0)

    move $a0, $s0
    move $a1, $s1
    jal  apply_capture

    move $a0, $s0
    move $a1, $s1
    move $a2, $s2
    jal  print_capture_feedback

    # Branch on ruleset for promotion & chaining behavior
    la   $t0, ruleset
    lw   $t0, 0($t0)
    bne  $t0, $zero, main_intl_chain

    # --- American Checkers (ruleset == 0) ---
    # Promote immediately; if a pawn just promoted on king-row, turn ENDS!
    la   $t0, board
    addiu $t1, $s1, -1
    addu $t0, $t0, $t1
    lbu  $s5, 0($t0)

    move $a0, $s1
    jal  check_promotion

    la   $t0, board
    addiu $t1, $s1, -1
    addu $t0, $t0, $t1
    lbu  $t2, 0($t0)
    beq  $t2, $s5, main_am_check_chain

    move $a0, $s1
    move $a1, $t2
    jal  print_promotion_feedback
    jal  finalize_captured_pieces
    j    main_after_move         # American rule: promotion ends turn immediately!

main_am_check_chain:
    move $a0, $s1
    jal  check_capture
    beq  $v0, $zero, main_cap_finish

    move $a0, $s1
    jal  chain_capture
    j    main_cap_finish

    # --- International Checkers (ruleset == 1) ---
    # Do NOT promote mid-chain; continue chaining, then remove captured pieces,
    # then promote ONLY if the piece ended its turn on the king-row.
main_intl_chain:
    move $s5, $s1                # $s5 = final square (default = first landing)

    move $a0, $s1
    jal  check_capture
    beq  $v0, $zero, main_intl_finalize

    move $a0, $s1
    jal  chain_capture           # $v1 = final landing square
    move $s5, $v1

main_intl_finalize:
    jal  finalize_captured_pieces

    la   $t0, board
    addiu $t1, $s5, -1
    addu $t0, $t0, $t1
    lbu  $s6, 0($t0)             # Piece before end-of-turn promotion

    move $a0, $s5
    jal  check_promotion

    la   $t0, board
    addiu $t1, $s5, -1
    addu $t0, $t0, $t1
    lbu  $t2, 0($t0)
    beq  $t2, $s6, main_after_move

    move $a0, $s5
    move $a1, $t2
    jal  print_promotion_feedback
    j    main_after_move

main_cap_finish:
    jal  finalize_captured_pieces

    # ------------------------------------------------------------------------
    # END OF TURN: check both elimination (0 pieces) and trapping (0 moves)
    # ------------------------------------------------------------------------
main_after_move:
    li   $t0, 3
    beq  $s2, $t0, main_opp_is_red
    li   $s3, 3
    j    main_check_win

main_opp_is_red:
    li   $s3, 1

main_check_win:
    move $a0, $s3
    jal  check_winner
    li   $t0, 1
    beq  $v0, $t0, main_handle_win_elim

    move $a0, $s3
    jal  player_has_any_legal_move
    beq  $v0, $zero, main_handle_win_trap

    jal  switch_player
    j    main_turn_loop

main_handle_win_elim:
    jal  print_board
    li   $a0, 0
    jal  print_win_reason
    move $a0, $s2
    jal  announce_winner
    j    main_turn_loop

main_handle_win_trap:
    jal  print_board
    li   $a0, 1
    jal  print_win_reason
    move $a0, $s2
    jal  announce_winner
    j    main_turn_loop

main_exit:
    li   $v0, 10
    syscall


# ============================================================================
# PLAYER HAS ANY LEGAL MOVE
# Scans squares 1..num_squares to check if player $a0 has any normal move or capture.
# ============================================================================
.globl player_has_any_legal_move
player_has_any_legal_move:
    addiu $sp, $sp, -16
    sw   $s0, 0($sp)
    sw   $s1, 4($sp)
    sw   $s2, 8($sp)
    sw   $ra, 12($sp)

    move $s0, $a0
    li   $s1, 1
    la   $t0, num_squares
    lw   $s2, 0($t0)

phm_loop:
    slt  $t0, $s2, $s1
    bne  $t0, $zero, phm_trapped

    move $a0, $s1
    move $a1, $s0
    jal  has_normal_move
    bne  $v0, $zero, phm_can_move

    move $a0, $s1
    move $a1, $s0
    jal  has_capture_from
    bne  $v0, $zero, phm_can_move

    addiu $s1, $s1, 1
    j    phm_loop

phm_can_move:
    li   $v0, 1
    j    phm_done

phm_trapped:
    li   $v0, 0

phm_done:
    lw   $s0, 0($sp)
    lw   $s1, 4($sp)
    lw   $s2, 8($sp)
    lw   $ra, 12($sp)
    addiu $sp, $sp, 16
    jr   $ra
