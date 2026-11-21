
# ============================================================================
# TEST HARNESS: MEMBER B - CAPTURE VALIDATION
#
# Tests validate_capture only.
# The board must remain unchanged after every validation.
#
# Piece encoding:
#   0 = Empty
#   1 = Red pawn
#   2 = Red king
#   3 = Black pawn
#   4 = Black king
# ============================================================================

.data

msg_title:
    .asciiz "\n========== MEMBER B: CAPTURE VALIDATION TESTS ==========\n"

msg_c1_pass:  .asciiz "C1: Black pawn forward capture: PASS\n"
msg_c1_fail:  .asciiz "C1: Black pawn forward capture: FAIL\n"

msg_c2_pass:  .asciiz "C2: Board unchanged after validation: PASS\n"
msg_c2_fail:  .asciiz "C2: Board unchanged after validation: FAIL\n"

msg_c3_pass:  .asciiz "C3: No opponent in middle: PASS\n"
msg_c3_fail:  .asciiz "C3: No opponent in middle: FAIL\n"

msg_c4_pass:  .asciiz "C4: Own piece in middle: PASS\n"
msg_c4_fail:  .asciiz "C4: Own piece in middle: FAIL\n"

msg_c5_pass:  .asciiz "C5: Destination occupied: PASS\n"
msg_c5_fail:  .asciiz "C5: Destination occupied: FAIL\n"

msg_c6_pass:  .asciiz "C6: Black pawn backward capture: PASS\n"
msg_c6_fail:  .asciiz "C6: Black pawn backward capture: FAIL\n"

msg_c7_pass:  .asciiz "C7: Black king backward capture: PASS\n"
msg_c7_fail:  .asciiz "C7: Black king backward capture: FAIL\n"

msg_c8_pass:  .asciiz "C8: Red pawn forward capture: PASS\n"
msg_c8_fail:  .asciiz "C8: Red pawn forward capture: FAIL\n"

msg_c9_pass:  .asciiz "C9: Wrong player's piece: PASS\n"
msg_c9_fail:  .asciiz "C9: Wrong player's piece: FAIL\n"

msg_c10_pass: .asciiz "C10: Invalid movement distance: PASS\n"
msg_c10_fail: .asciiz "C10: Invalid movement distance: FAIL\n"

msg_end:
    .asciiz "========== TESTING FINISHED ==========\n"


.text
.globl main

main:

    # =================================================
    # START TESTING
    # =================================================

    li $v0, 4
    la $a0, msg_title
    syscall


    # =================================================
    # C1: VALID BLACK PAWN FORWARD CAPTURE
    #
    # Start:      21 = Black pawn (3)
    # Middle:     17 = Red pawn (1)
    # Destination:14 = Empty (0)
    #
    # Expected: VALID (1)
    # =================================================

    jal clear_board

    la   $t0, board

    li   $t1, 3
    sb   $t1, 20($t0)       # Square 21 = Black pawn

    li   $t1, 1
    sb   $t1, 16($t0)       # Square 17 = Red pawn

    li   $a0, 21
    li   $a1, 14
    li   $a2, 3             # Black player
    li   $a3, 1             # Expected result

    jal run_capture_test

    bne  $v0, $zero, c1_pass

    li   $v0, 4
    la   $a0, msg_c1_fail
    syscall
    j c2_test

c1_pass:

    li   $v0, 4
    la   $a0, msg_c1_pass
    syscall


    # =================================================
    # C2: VALIDATION MUST NOT MODIFY BOARD
    #
    # After C1:
    # Square 21 must still contain Black pawn.
    # Square 17 must still contain Red pawn.
    # Square 14 must still be empty.
    # =================================================

c2_test:

    la   $t0, board

    lbu  $t1, 20($t0)
    li   $t2, 3
    bne  $t1, $t2, c2_fail

    lbu  $t1, 16($t0)
    li   $t2, 1
    bne  $t1, $t2, c2_fail

    lbu  $t1, 13($t0)
    bne  $t1, $zero, c2_fail

    li   $v0, 4
    la   $a0, msg_c2_pass
    syscall

    j c3_test

c2_fail:

    li   $v0, 4
    la   $a0, msg_c2_fail
    syscall


    # =================================================
    # C3: NO OPPONENT IN MIDDLE SQUARE
    #
    # Start:      21 = Black pawn
    # Middle:     17 = Empty
    # Destination:14 = Empty
    #
    # Expected: INVALID (0)
    # =================================================

c3_test:

    jal clear_board

    la   $t0, board

    li   $t1, 3
    sb   $t1, 20($t0)       # Black pawn at 21

    li   $a0, 21
    li   $a1, 14
    li   $a2, 3
    li   $a3, 0

    jal run_capture_test

    bne  $v0, $zero, c3_pass

    li   $v0, 4
    la   $a0, msg_c3_fail
    syscall
    j c4_test

c3_pass:

    li   $v0, 4
    la   $a0, msg_c3_pass
    syscall


    # =================================================
    # C4: OWN PIECE IN MIDDLE SQUARE
    #
    # Start:      21 = Black pawn
    # Middle:     17 = Black pawn
    # Destination:14 = Empty
    #
    # Expected: INVALID (0)
    # =================================================

c4_test:

    jal clear_board

    la   $t0, board

    li   $t1, 3
    sb   $t1, 20($t0)       # Black at 21
    sb   $t1, 16($t0)       # Black at 17

    li   $a0, 21
    li   $a1, 14
    li   $a2, 3
    li   $a3, 0

    jal run_capture_test

    bne  $v0, $zero, c4_pass

    li   $v0, 4
    la   $a0, msg_c4_fail
    syscall
    j c5_test

c4_pass:

    li   $v0, 4
    la   $a0, msg_c4_pass
    syscall


    # =================================================
    # C5: DESTINATION OCCUPIED
    #
    # Start:      21 = Black pawn
    # Middle:     17 = Red pawn
    # Destination:14 = Red pawn
    #
    # Expected: INVALID (0)
    # =================================================

c5_test:

    jal clear_board

    la   $t0, board

    li   $t1, 3
    sb   $t1, 20($t0)       # Black at 21

    li   $t1, 1
    sb   $t1, 16($t0)       # Red at 17
    sb   $t1, 13($t0)       # Red at 14

    li   $a0, 21
    li   $a1, 14
    li   $a2, 3
    li   $a3, 0

    jal run_capture_test

    bne  $v0, $zero, c5_pass

    li   $v0, 4
    la   $a0, msg_c5_fail
    syscall
    j c6_test

c5_pass:

    li   $v0, 4
    la   $a0, msg_c5_pass
    syscall


    # =================================================
    # C6: BLACK PAWN CANNOT CAPTURE BACKWARDS
    #
    # Start:      14 = Black pawn
    # Middle:     18 = Red pawn
    # Destination:23 = Empty
    #
    # Row increases by 2: Black moves backwards.
    #
    # Expected: INVALID (0)
    # =================================================

c6_test:

    jal clear_board

    la   $t0, board

    li   $t1, 3
    sb   $t1, 13($t0)       # Black pawn at 14

    li   $t1, 1
    sb   $t1, 17($t0)       # Red pawn at 18

    li   $a0, 14
    li   $a1, 23
    li   $a2, 3
    li   $a3, 0

    jal run_capture_test

    bne  $v0, $zero, c6_pass

    li   $v0, 4
    la   $a0, msg_c6_fail
    syscall
    j c7_test

c6_pass:

    li   $v0, 4
    la   $a0, msg_c6_pass
    syscall


    # =================================================
    # C7: BLACK KING CAN CAPTURE BACKWARDS
    #
    # Start:      14 = Black king
    # Middle:     18 = Red pawn
    # Destination:23 = Empty
    #
    # Expected: VALID (1)
    # =================================================

c7_test:

    jal clear_board

    la   $t0, board

    li   $t1, 4
    sb   $t1, 13($t0)       # Black king at 14

    li   $t1, 1
    sb   $t1, 17($t0)       # Red pawn at 18

    li   $a0, 14
    li   $a1, 23
    li   $a2, 3
    li   $a3, 1

    jal run_capture_test

    bne  $v0, $zero, c7_pass

    li   $v0, 4
    la   $a0, msg_c7_fail
    syscall
    j c8_test

c7_pass:

    li   $v0, 4
    la   $a0, msg_c7_pass
    syscall


    # =================================================
    # C8: RED PAWN CAN CAPTURE FORWARDS
    #
    # Start:      14 = Red pawn
    # Middle:     18 = Black pawn
    # Destination:23 = Empty
    #
    # Expected: VALID (1)
    # =================================================

c8_test:

    jal clear_board

    la   $t0, board

    li   $t1, 1
    sb   $t1, 13($t0)       # Red pawn at 14

    li   $t1, 3
    sb   $t1, 17($t0)       # Black pawn at 18

    li   $a0, 14
    li   $a1, 23
    li   $a2, 1             # Red player
    li   $a3, 1

    jal run_capture_test

    bne  $v0, $zero, c8_pass

    li   $v0, 4
    la   $a0, msg_c8_fail
    syscall
    j c9_test

c8_pass:

    li   $v0, 4
    la   $a0, msg_c8_pass
    syscall


    # =================================================
    # C9: WRONG PLAYER'S PIECE
    #
    # Current player: Black
    # Starting piece: Red pawn
    #
    # Expected: INVALID (0)
    # =================================================

c9_test:

    jal clear_board

    la   $t0, board

    li   $t1, 1
    sb   $t1, 20($t0)       # Red pawn at 21

    li   $t1, 3
    sb   $t1, 16($t0)       # Black pawn at 17

    li   $a0, 21
    li   $a1, 14
    li   $a2, 3             # Black's turn
    li   $a3, 0

    jal run_capture_test

    bne  $v0, $zero, c9_pass

    li   $v0, 4
    la   $a0, msg_c9_fail
    syscall
    j c10_test

c9_pass:

    li   $v0, 4
    la   $a0, msg_c9_pass
    syscall


    # =================================================
    # C10: INVALID MOVEMENT DISTANCE
    #
    # Start:       21 = Black pawn (5,0)
    # Destination: 18 = Empty (4,3)
    #
    # Not a two-square diagonal movement.
    #
    # Expected: INVALID (0)
    # =================================================

c10_test:

    jal clear_board

    la   $t0, board

    li   $t1, 3
    sb   $t1, 20($t0)       # Black pawn at 21

    li   $a0, 21
    li   $a1, 18
    li   $a2, 3
    li   $a3, 0

    jal run_capture_test

    bne  $v0, $zero, c10_pass

    li   $v0, 4
    la   $a0, msg_c10_fail
    syscall
    j tests_finished

c10_pass:

    li   $v0, 4
    la   $a0, msg_c10_pass
    syscall


# =====================================================
# END TESTING
# =====================================================

tests_finished:

    li $v0, 4
    la $a0, msg_end
    syscall

    li $v0, 10
    syscall


# ============================================================================
# HELPER 1: CLEAR THE 32-BYTE BOARD
# ============================================================================

clear_board:

    la   $t0, board
    li   $t1, 0
    li   $t2, 32

clear_board_loop:

    beq  $t1, $t2, clear_board_done

    sb   $zero, 0($t0)

    addi $t0, $t0, 1
    addi $t1, $t1, 1

    j clear_board_loop

clear_board_done:

    jr $ra


# ============================================================================
# HELPER 2: RUN ONE CAPTURE VALIDATION TEST
#
# Input:
#   $a0 = starting square
#   $a1 = destination square
#   $a2 = current player
#   $a3 = expected result (1 or 0)
#
# Output:
#   $v0 = 1 if actual result matches expected result
#   $v0 = 0 otherwise
# ============================================================================

run_capture_test:

    addiu $sp, $sp, -8

    sw $s0, 0($sp)
    sw $ra, 4($sp)

    move $s0, $a3

    jal validate_capture

    beq $v0, $s0, test_result_pass

    li $v0, 0
    j test_result_done

test_result_pass:

    li $v0, 1

test_result_done:

    lw $s0, 0($sp)
    lw $ra, 4($sp)

    addiu $sp, $sp, 8

    jr $ra

# =====================================================
# INCLUDE REQUIRED MODULES
# =====================================================

.include "../src/board.asm"
.include "../src/coordinates.asm"
.include "../src/promotion.asm"
.include "../src/capture.asm"
