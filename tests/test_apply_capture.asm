
# ============================================================================
# TEST HARNESS: MEMBER B - APPLY CAPTURE
# ============================================================================

.data

msg_title:
    .asciiz "\n========== APPLY CAPTURE TESTS ==========\n"

msg_c1_pass:
    .asciiz "C1: Valid capture updates all three squares: PASS\n"

msg_c1_fail:
    .asciiz "C1: Valid capture updates all three squares: FAIL\n"

msg_c2_pass:
    .asciiz "C2: Invalid capture leaves board unchanged: PASS\n"

msg_c2_fail:
    .asciiz "C2: Invalid capture leaves board unchanged: FAIL\n"

msg_end:
    .asciiz "========== TESTING FINISHED ==========\n"


.text
.globl main

main:

    # ------------------------------------------------
    # Display test title
    # ------------------------------------------------

    li $v0, 4
    la $a0, msg_title
    syscall


    # =================================================
    # C1: VALID CAPTURE
    #
    # Black pawn: square 21
    # Red pawn:   square 17
    # Destination: square 14
    #
    # Expected:
    # board[20] = 0
    # board[16] = 0
    # board[13] = 3
    # =================================================

    jal ap_test_clear_board

    # Set current player = Black

    la   $t0, current_player
    li   $t1, 3
    sw   $t1, 0($t0)

    # Set Black pawn on square 21

    la   $t0, board
    li   $t1, 3
    sb   $t1, 20($t0)

    # Set Red pawn on square 17

    li   $t1, 1
    sb   $t1, 16($t0)

    # Execute capture: 21 -> 14

    li   $a0, 21
    li   $a1, 14

    jal apply_capture

    # Capture should return 1

    beq $v0, $zero, ap_c1_fail


    # Check starting square = empty

    la   $t0, board
    lbu  $t1, 20($t0)

    bne  $t1, $zero, ap_c1_fail


    # Check middle square = empty

    lbu  $t1, 16($t0)

    bne  $t1, $zero, ap_c1_fail


    # Check destination = Black pawn (3)

    lbu  $t1, 13($t0)

    li   $t2, 3
    bne  $t1, $t2, ap_c1_fail


    # C1 PASS

    li $v0, 4
    la $a0, msg_c1_pass
    syscall

    j ap_c2_test


ap_c1_fail:

    li $v0, 4
    la $a0, msg_c1_fail
    syscall


    # =================================================
    # C2: INVALID CAPTURE MUST NOT MODIFY BOARD
    #
    # Black pawn: square 21
    # Middle: square 17 is empty
    # Destination: square 14 is empty
    #
    # Expected:
    # $v0 = 0
    # board[20] = 3
    # board[16] = 0
    # board[13] = 0
    # =================================================

ap_c2_test:

    jal ap_test_clear_board

    # Current player = Black

    la   $t0, current_player
    li   $t1, 3
    sw   $t1, 0($t0)

    # Place Black pawn on square 21

    la   $t0, board
    li   $t1, 3
    sb   $t1, 20($t0)

    # No opponent is placed on square 17.

    # Attempt invalid capture

    li   $a0, 21
    li   $a1, 14

    jal apply_capture

    # Must return 0

    bne $v0, $zero, ap_c2_fail


    # Check starting square still contains Black

    la   $t0, board
    lbu  $t1, 20($t0)

    li   $t2, 3
    bne  $t1, $t2, ap_c2_fail


    # Check middle square remains empty

    lbu  $t1, 16($t0)

    bne  $t1, $zero, ap_c2_fail


    # Check destination remains empty

    lbu  $t1, 13($t0)

    bne  $t1, $zero, ap_c2_fail


    # C2 PASS

    li $v0, 4
    la $a0, msg_c2_pass
    syscall

    j ap_tests_finished


ap_c2_fail:

    li $v0, 4
    la $a0, msg_c2_fail
    syscall


# =====================================================
# FINISH TESTING
# =====================================================

ap_tests_finished:

    li $v0, 4
    la $a0, msg_end
    syscall

    li $v0, 10
    syscall


# =====================================================
# HELPER: CLEAR ALL 32 PLAYABLE SQUARES
# =====================================================

ap_test_clear_board:

    la   $t0, board
    li   $t1, 0
    li   $t2, 32

ap_clear_loop:

    beq  $t1, $t2, ap_clear_done

    sb   $zero, 0($t0)

    addi $t0, $t0, 1
    addi $t1, $t1, 1

    j ap_clear_loop

ap_clear_done:

    jr $ra


# =====================================================
# INCLUDE REQUIRED MODULES
# =====================================================

.include "../src/coordinates.asm"
.include "../src/board.asm"
.include "../src/promotion.asm"
.include "../src/capture.asm"
