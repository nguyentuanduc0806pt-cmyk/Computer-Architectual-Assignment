# ============================================================================
# CO2008 CHECKERS — PROGRAM ENTRY POINT & MAIN GAME LOOP
# Owner: Member B
# MARS 4.5: Open this file with "Assemble all files in directory" enabled.
# ============================================================================

.data
main_welcome_msg:  .asciiz "========================================\n       CO2008 CHECKERS (MIPS)\n   Black (b/B) moves first vs Red (r/R)\n========================================\n"
main_invalid_msg:  .asciiz "Invalid move! Please try again.\n"

.text
.globl main
main:
    # 1. Print welcome banner
    li   $v0, 4
    la   $a0, main_welcome_msg
    syscall

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

    jal  print_board             # Member A: display current 8x8 board
    jal  print_turn_banner       # Member B: announce BLACK's or RED's turn

    # ------------------------------------------------------------------------
    # INPUT & RETRY LOOP: repeats until the active player enters a legal move
    # ------------------------------------------------------------------------
main_input_loop:
    jal  read_player_move        # $v0 = start_square, $v1 = destination
    move $s0, $v0                # $s0 = start_square (saved across all jal calls)
    move $s1, $v1                # $s1 = destination  (saved across all jal calls)

    la   $t0, current_player
    lw   $s2, 0($t0)             # $s2 = current_player (1 or 3)

    # ---- Attempt 1: Normal 1-square diagonal move ----
    move $a0, $s0                # $a0 = start
    move $a1, $s1                # $a1 = destination
    move $a2, $s2                # $a2 = current_player
    jal  validate_normal_move    # Member A (read-only) -> $v0 = 1 if valid

    bne  $v0, $zero, main_do_normal_move

    # ---- Attempt 2: 2-square diagonal capture ----
    move $a0, $s0                # Reload $a0-$a2! Previous jal may clobber them
    move $a1, $s1
    move $a2, $s2
    jal  validate_capture        # Member B (read-only) -> $v0 = 1 if valid

    bne  $v0, $zero, main_do_capture

    # ---- Neither valid: reject move and retry same turn ----
    li   $v0, 4
    la   $a0, main_invalid_msg
    syscall
    j    main_input_loop         # Board untouched, current_player unchanged!

    # ------------------------------------------------------------------------
    # EXECUTE NORMAL MOVE
    # ------------------------------------------------------------------------
main_do_normal_move:
    move $a0, $s0                # $a0 = start
    move $a1, $s1                # $a1 = destination
    jal  apply_normal_move       # Member A: move piece & clear start

    move $a0, $s1                # $a0 = destination square
    jal  check_promotion         # Member A: promote pawn if it reached final row

    j    main_after_move

    # ------------------------------------------------------------------------
    # EXECUTE CAPTURE (+ IMMEDIATE PROMOTION + MANDATORY CHAIN CAPTURE)
    # ------------------------------------------------------------------------
main_do_capture:
    move $a0, $s0                # $a0 = start
    move $a1, $s1                # $a1 = destination
    jal  apply_capture           # Member B: move piece, clear start & middle

    # Promotion MUST happen BEFORE check_capture so a newly crowned King
    # can immediately continue capturing backwards in the same chain!
    move $a0, $s1                # $a0 = destination square
    jal  check_promotion         # Member A

    # Check whether another jump is available from the landing square
    move $a0, $s1                # $a0 = current square (reads global current_player)
    jal  check_capture           # Member B -> $v0 = 1 if chain capture exists

    beq  $v0, $zero, main_after_move  # No follow-up jump -> turn is done

    # Show updated board so player can see where their piece is before chaining
    jal  print_board

    move $a0, $s1                # $a0 = current square of capturing piece
    jal  chain_capture           # Member B: loops until no more captures remain

    # ------------------------------------------------------------------------
    # END OF TURN: check whether the opponent has any pieces left
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
    move $a0, $s3                # $a0 = opponent to check
    jal  check_winner            # Member B -> $v0 = 1 if opponent has 0 pieces

    li   $t0, 1
    beq  $v0, $t0, main_handle_win

    # Opponent still has pieces -> switch turn and continue
    jal  switch_player
    j    main_turn_loop

main_handle_win:
    jal  print_board             # Display final board state
    move $a0, $s2                # $a0 = current_player (the winner!)
    jal  announce_winner         # Sets game_over = 1 and prints winner banner
    j    main_turn_loop          # Loop header sees game_over == 1 -> exits cleanly

    # ------------------------------------------------------------------------
    # PROGRAM EXIT
    # ------------------------------------------------------------------------
main_exit:
    li   $v0, 10                 # Syscall 10: terminate execution
    syscall