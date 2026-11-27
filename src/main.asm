# ============================================================================
# CO2008 CHECKERS — PROGRAM ENTRY POINT & MAIN GAME LOOP
# Owner: Member B
# MARS 4.5: Open this file with "Assemble all files in directory" enabled.
# ============================================================================

.data
main_welcome_msg:       .asciiz "========================================\n       CO2008 CHECKERS (MIPS)\n   Black (b/B) moves first vs Red (r/R)\n========================================\n"
main_mand_cap_msg:      .asciiz "Mandatory capture! Pieces that can capture: "
main_bad_range_msg:     .asciiz "Invalid square! Please enter a number from 1 to 32.\n"
main_empty_sq_msg:      .asciiz "Square is empty! Please select one of your own pieces.\n"
main_wrong_owner_msg:   .asciiz "That piece belongs to your opponent! Select your own piece.\n"
main_sel_pre_msg:       .asciiz "Selected square "
main_sel_mid_msg:       .asciiz " ("
main_sel_post_msg:      .asciiz ").\n"
main_must_cap_piece:    .asciiz "This piece cannot capture! Choose one of the pieces with a mandatory capture.\n"
main_no_moves_msg:      .asciiz "This piece has no legal moves! Please choose another piece.\n"
main_legal_moves_msg:   .asciiz "  Legal moves: "
main_legal_caps_msg:    .asciiz "  Legal captures: "
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
    jal  choose_game_mode        # Sets mandatory_capture (1 = Official, 0 = Casual)

    # 2. Initialize board and shared game-state globals
    jal  init_board              # Member A: fills board[0..31] (12 Red, 8 empty, 12 Black)

    la   $t0, current_player
    li   $t1, 3                  # Black moves first (assignment rule)
    sw   $t1, 0($t0)

    la   $t0, game_over
    sw   $zero, 0($t0)           # game_over = 0 (game is running)

    # ------------------------------------------------------------------------
    # OUTER GAME LOOP: runs once per turn until game_over != 0
    # ------------------------------------------------------------------------
main_turn_loop:
    la   $t0, game_over
    lw   $t1, 0($t0)
    bne  $t1, $zero, main_exit   # If game_over != 0, stop program

    jal  print_board             # Member A: display enhanced 8x8 board + 1-32 map
    jal  print_turn_banner       # Member B: announce Player 1 / Player 2 turn

    la   $t0, current_player
    lw   $s2, 0($t0)             # $s2 = current_player (1 or 3)

    # Determine whether a mandatory capture is enforced on this turn ($s4 = 1/0)
    li   $s4, 0
    la   $t0, mandatory_capture
    lw   $t1, 0($t0)
    beq  $t1, $zero, main_select_piece

    move $a0, $s2
    jal  has_any_capture
    beq  $v0, $zero, main_select_piece

    li   $s4, 1                  # Active player MUST capture on this turn
    li   $v0, 4
    la   $a0, main_mand_cap_msg
    syscall

    move $a0, $s2
    jal  print_mandatory_capture_pieces

    li   $a0, 10                 # '\n'
    li   $v0, 11
    syscall

    # ------------------------------------------------------------------------
    # STEP 1: SELECT PIECE & DISPLAY ITS LEGAL MOVES
    # ------------------------------------------------------------------------
main_select_piece:
    jal  read_start_square       # $v0 = start_square (also stored in global)
    move $s0, $v0                # $s0 = start_square

    # Validate range 1..32
    slti $t0, $s0, 1
    bne  $t0, $zero, main_err_range
    slti $t0, $s0, 33
    beq  $t0, $zero, main_err_range

    # Load piece at start square and verify ownership
    la   $t0, board
    addiu $t1, $s0, -1
    addu $t0, $t0, $t1
    lbu  $s5, 0($t0)             # $s5 = piece code at start

    beq  $s5, $zero, main_err_empty

    li   $t0, 1
    beq  $s2, $t0, main_check_red_own

    # Current player is Black (3): piece must be 3 or 4
    li   $t0, 3
    beq  $s5, $t0, main_piece_owned
    li   $t0, 4
    beq  $s5, $t0, main_piece_owned
    j    main_err_owner

main_check_red_own:
    # Current player is Red (1): piece must be 1 or 2
    li   $t0, 1
    beq  $s5, $t0, main_piece_owned
    li   $t0, 2
    beq  $s5, $t0, main_piece_owned
    j    main_err_owner

main_piece_owned:
    # Print selected square and piece type: "Selected square <n> (<piece>)."
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

    # Query available captures ($s6) and normal moves ($s7) for selected piece
    move $a0, $s0
    move $a1, $s2
    jal  has_capture_from
    move $s6, $v0                # $s6 = 1 if selected piece can capture

    move $a0, $s0
    move $a1, $s2
    jal  has_normal_move
    move $s7, $v0                # $s7 = 1 if selected piece has a normal move

    # If mandatory capture is active this turn, only capture moves are legal
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
    j    main_select_dest

main_show_mandatory_caps:
    beq  $s6, $zero, main_err_must_cap
    li   $v0, 4
    la   $a0, main_legal_caps_msg
    syscall
    move $a0, $s0
    move $a1, $s2
    jal  print_capture_moves
    li   $a0, 10
    li   $v0, 11
    syscall
    j    main_select_dest

main_err_range:
    li   $v0, 4
    la   $a0, main_bad_range_msg
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

main_err_no_moves:
    li   $v0, 4
    la   $a0, main_no_moves_msg
    syscall
    j    main_select_piece

    # ------------------------------------------------------------------------
    # STEP 2: SELECT DESTINATION SQUARE (0 = RESELECT ANOTHER PIECE)
    # ------------------------------------------------------------------------
main_select_dest:
    jal  read_dest_square        # $v0 = destination (also stored in global)
    move $s1, $v0                # $s1 = destination

    beq  $s1, $zero, main_select_piece  # 0 -> cancel and pick another piece

    # If mandatory capture is active, only a valid capture is permitted
    bne  $s4, $zero, main_try_mandatory_cap

    # ---- Attempt 1: Normal 1-square diagonal move ----
    move $a0, $s0
    move $a1, $s1
    move $a2, $s2
    jal  validate_normal_move    # Member A (read-only) -> $v0 = 1 if valid
    bne  $v0, $zero, main_do_normal_move

    # ---- Attempt 2: 2-square diagonal capture ----
    move $a0, $s0
    move $a1, $s1
    move $a2, $s2
    jal  validate_capture        # Member B (read-only) -> $v0 = 1 if valid
    bne  $v0, $zero, main_do_capture

    li   $v0, 4
    la   $a0, main_bad_dest_msg
    syscall
    j    main_select_dest

main_try_mandatory_cap:
    move $a0, $s0
    move $a1, $s1
    move $a2, $s2
    jal  validate_capture
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
    jal  apply_normal_move       # Member A: move piece & clear start

    move $a0, $s0
    move $a1, $s1
    jal  print_move_feedback     # Standard notation: "Move played: <start>-<dest>"

    # Record piece before promotion so we can announce newly crowned Kings
    la   $t0, board
    addiu $t1, $s1, -1
    addu $t0, $t0, $t1
    lbu  $s5, 0($t0)

    move $a0, $s1
    jal  check_promotion         # Member A: promote pawn if it reached final row

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
    # EXECUTE CAPTURE + FEEDBACK + IMMEDIATE PROMOTION + MANDATORY CHAIN
    # ------------------------------------------------------------------------
main_do_capture:
    move $a0, $s0
    move $a1, $s1
    jal  apply_capture           # Member B: move piece, clear start & middle

    move $a0, $s0
    move $a1, $s1
    move $a2, $s2
    jal  print_capture_feedback  # Standard notation: "Captured ... (<start>x<dest>)"

    # Promotion MUST happen BEFORE check_capture so a newly crowned King
    # can immediately continue capturing backwards in the same chain!
    la   $t0, board
    addiu $t1, $s1, -1
    addu $t0, $t0, $t1
    lbu  $s5, 0($t0)

    move $a0, $s1
    jal  check_promotion         # Member A

    la   $t0, board
    addiu $t1, $s1, -1
    addu $t0, $t0, $t1
    lbu  $t2, 0($t0)
    beq  $t2, $s5, main_check_chain

    move $a0, $s1
    move $a1, $t2
    jal  print_promotion_feedback

main_check_chain:
    # Check whether another jump is available from the landing square
    move $a0, $s1
    jal  check_capture           # Member B -> $v0 = 1 if chain capture exists
    beq  $v0, $zero, main_after_move

    move $a0, $s1
    jal  chain_capture           # Prints board, lists jumps, executes & promotes

    # ------------------------------------------------------------------------
    # END OF TURN: check both elimination (0 pieces) and trapping (0 moves)
    # ------------------------------------------------------------------------
main_after_move:
    # Determine opponent player code into $s3
    li   $t0, 3
    beq  $s2, $t0, main_opp_is_red
    li   $s3, 3                  # Current player was Red (1) -> opponent is Black (3)
    j    main_check_win

main_opp_is_red:
    li   $s3, 1                  # Current player was Black (3) -> opponent is Red (1)

main_check_win:
    # 1. Did opponent lose all pieces?
    move $a0, $s3
    jal  check_winner            # $v0 = 1 if opponent has 0 pieces
    li   $t0, 1
    beq  $v0, $t0, main_handle_win_elim

    # 2. Is opponent completely trapped (no legal normal move or capture)?
    move $a0, $s3
    jal  player_has_any_legal_move
    beq  $v0, $zero, main_handle_win_trap

    # Opponent can still play -> switch turn and continue
    jal  switch_player
    j    main_turn_loop

main_handle_win_elim:
    jal  print_board             # Display final board state
    li   $a0, 0                  # Reason 0: all opponent pieces captured
    jal  print_win_reason
    move $a0, $s2                # $a0 = current_player (the winner)
    jal  announce_winner         # Sets game_over = 1 and prints winner banner
    j    main_turn_loop          # Loop header sees game_over == 1 -> exits cleanly

main_handle_win_trap:
    jal  print_board             # Display final board state
    li   $a0, 1                  # Reason 1: opponent trapped with no legal moves
    jal  print_win_reason
    move $a0, $s2                # $a0 = current_player (the winner)
    jal  announce_winner
    j    main_turn_loop

    # ------------------------------------------------------------------------
    # PROGRAM EXIT
    # ------------------------------------------------------------------------
main_exit:
    li   $v0, 10                 # Syscall 10: terminate execution
    syscall


# ============================================================================
# PLAYER HAS ANY LEGAL MOVE
# Scans squares 1..32 to determine whether player $a0 has at least one legal
# normal move OR capture anywhere on the board (used for trap-win detection).
# Read-only: does NOT modify board or global state.
#
# Input:  $a0 = player to check (1 = Red, 3 = Black)
# Output: $v0 = 1 if at least one legal move exists, 0 if trapped
# ============================================================================
.globl player_has_any_legal_move
player_has_any_legal_move:
    addiu $sp, $sp, -16
    sw   $s0, 0($sp)
    sw   $s1, 4($sp)
    sw   $ra, 8($sp)

    move $s0, $a0                # $s0 = player
    li   $s1, 1                  # $s1 = square (1..32)

phm_loop:
    slti $t0, $s1, 33
    beq  $t0, $zero, phm_trapped

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
    lw   $ra, 8($sp)
    addiu $sp, $sp, 16
    jr   $ra
