
# ============================================================================
# MEMBER B - CHECK CAPTURE TESTS
# ============================================================================

.data

cc_title:
    .asciiz "\n========== CHECK CAPTURE TESTS ==========\n"

cc1_pass:
    .asciiz "CC1: Black pawn has forward capture: PASS\n"
cc1_fail:
    .asciiz "CC1: Black pawn has forward capture: FAIL\n"

cc2_pass:
    .asciiz "CC2: Black pawn has no capture: PASS\n"
cc2_fail:
    .asciiz "CC2: Black pawn has no capture: FAIL\n"

cc3_pass:
    .asciiz "CC3: Black pawn cannot capture backwards: PASS\n"
cc3_fail:
    .asciiz "CC3: Black pawn cannot capture backwards: FAIL\n"

cc4_pass:
    .asciiz "CC4: Black king can capture backwards: PASS\n"
cc4_fail:
    .asciiz "CC4: Black king can capture backwards: FAIL\n"

cc5_pass:
    .asciiz "CC5: Red pawn has forward capture: PASS\n"
cc5_fail:
    .asciiz "CC5: Red pawn has forward capture: FAIL\n"

cc_end:
    .asciiz "========== TESTING FINISHED ==========\n"


.text
.globl main

main:

    li $v0, 4
    la $a0, cc_title
    syscall


    # =================================================
    # CC1: BLACK PAWN HAS FORWARD CAPTURE
    #
    # 21 = Black pawn
    # 17 = Red pawn
    # 14 = Empty
    # =================================================

    jal cc_clear_board

    la $t0, board

    li $t1, 3
    sb $t1, 20($t0)

    li $t1, 1
    sb $t1, 16($t0)

    li $a0, 21
    li $a1, 3
    li $a2, 1

    jal run_check_test

    beq $v0, $zero, cc1_failed

    li $v0, 4
    la $a0, cc1_pass
    syscall

    j cc2_test

cc1_failed:

    li $v0, 4
    la $a0, cc1_fail
    syscall


    # =================================================
    # CC2: BLACK PAWN HAS NO CAPTURE
    # =================================================

cc2_test:

    jal cc_clear_board

    la $t0, board

    li $t1, 3
    sb $t1, 20($t0)

    li $a0, 21
    li $a1, 3
    li $a2, 0

    jal run_check_test

    beq $v0, $zero, cc2_failed

    li $v0, 4
    la $a0, cc2_pass
    syscall

    j cc3_test

cc2_failed:

    li $v0, 4
    la $a0, cc2_fail
    syscall


    # =================================================
    # CC3: BLACK PAWN CANNOT CAPTURE BACKWARDS
    #
    # 14 = Black pawn
    # 18 = Red pawn
    # 23 = Empty
    # =================================================

cc3_test:

    jal cc_clear_board

    la $t0, board

    li $t1, 3
    sb $t1, 13($t0)

    li $t1, 1
    sb $t1, 17($t0)

    li $a0, 14
    li $a1, 3
    li $a2, 0

    jal run_check_test

    beq $v0, $zero, cc3_failed

    li $v0, 4
    la $a0, cc3_pass
    syscall

    j cc4_test

cc3_failed:

    li $v0, 4
    la $a0, cc3_fail
    syscall


    # =================================================
    # CC4: BLACK KING CAN CAPTURE BACKWARDS
    #
    # 14 = Black king
    # 18 = Red pawn
    # 23 = Empty
    # =================================================

cc4_test:

    jal cc_clear_board

    la $t0, board

    li $t1, 4
    sb $t1, 13($t0)

    li $t1, 1
    sb $t1, 17($t0)

    li $a0, 14
    li $a1, 3
    li $a2, 1

    jal run_check_test

    beq $v0, $zero, cc4_failed

    li $v0, 4
    la $a0, cc4_pass
    syscall

    j cc5_test

cc4_failed:

    li $v0, 4
    la $a0, cc4_fail
    syscall


    # =================================================
    # CC5: RED PAWN HAS FORWARD CAPTURE
    #
    # 14 = Red pawn
    # 18 = Black pawn
    # 23 = Empty
    # =================================================

cc5_test:

    jal cc_clear_board

    la $t0, board

    li $t1, 1
    sb $t1, 13($t0)

    li $t1, 3
    sb $t1, 17($t0)

    li $a0, 14
    li $a1, 1
    li $a2, 1

    jal run_check_test

    beq $v0, $zero, cc5_failed

    li $v0, 4
    la $a0, cc5_pass
    syscall

    j cc_tests_finished

cc5_failed:

    li $v0, 4
    la $a0, cc5_fail
    syscall


# =====================================================
# FINISH
# =====================================================

cc_tests_finished:

    li $v0, 4
    la $a0, cc_end
    syscall

    li $v0, 10
    syscall


# =====================================================
# HELPER: CLEAR BOARD
# =====================================================

cc_clear_board:

    la $t0, board
    li $t1, 0
    li $t2, 32

cc_clear_loop:

    beq $t1, $t2, cc_clear_done

    sb $zero, 0($t0)

    addi $t0, $t0, 1
    addi $t1, $t1, 1

    j cc_clear_loop

cc_clear_done:

    jr $ra


# =====================================================
# HELPER: RUN ONE CHECK CAPTURE TEST
#
# $a0 = current square
# $a1 = current player
# $a2 = expected result
# =====================================================

run_check_test:

    addiu $sp, $sp, -16

    sw $s0, 0($sp)
    sw $s1, 4($sp)
    sw $s2, 8($sp)
    sw $ra, 12($sp)

    move $s0, $a2       # Expected result
    move $s1, $a1       # Current player
    move $s2, $a0       # Current square

    # Set shared current_player variable
    la   $t0, current_player
    sw   $s1, 0($t0)

    # check_capture only needs current square
    move $a0, $s2
    jal  check_capture

    beq $v0, $s0, check_test_pass

    li $v0, 0
    j check_test_done

check_test_pass:

    li $v0, 1

check_test_done:

    lw $s0, 0($sp)
    lw $s1, 4($sp)
    lw $s2, 8($sp)
    lw $ra, 12($sp)

    addiu $sp, $sp, 16

    jr $ra

cc_result_pass:

    li $v0, 1

cc_result_done:

    lw $s0, 0($sp)
    lw $ra, 4($sp)

    addiu $sp, $sp, 8

    jr $ra


# =====================================================
# INCLUDE MODULES
# =====================================================

.include "../src/board.asm"
.include "../src/coordinates.asm"
.include "../src/capture.asm"
.include "../src/promotion.asm"
