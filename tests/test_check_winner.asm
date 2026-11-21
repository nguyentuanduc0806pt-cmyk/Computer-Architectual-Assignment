
# ============================================================================
# MEMBER B - WINNER DETECTION TESTS
# ============================================================================

.data

cw_title:
    .asciiz "\n========== CHECK WINNER TESTS ==========\n"

cw1_pass:
    .asciiz "W1: Red pawn exists: PASS\n"
cw1_fail:
    .asciiz "W1: Red pawn exists: FAIL\n"

cw2_pass:
    .asciiz "W2: Black king exists: PASS\n"
cw2_fail:
    .asciiz "W2: Black king exists: FAIL\n"

cw3_pass:
    .asciiz "W3: Red eliminated: PASS\n"
cw3_fail:
    .asciiz "W3: Red eliminated: FAIL\n"

cw4_pass:
    .asciiz "W4: Black eliminated: PASS\n"
cw4_fail:
    .asciiz "W4: Black eliminated: FAIL\n"

cw5_pass:
    .asciiz "W5: Both players eliminated on empty board: PASS\n"
cw5_fail:
    .asciiz "W5: Both players eliminated on empty board: FAIL\n"

cw_end:
    .asciiz "========== TESTING FINISHED ==========\n"


.text
.globl main

main:

    li $v0, 4
    la $a0, cw_title
    syscall


    # =================================================
    # W1: RED PAWN EXISTS
    #
    # Expected:
    # check_winner(1) = 0
    # =================================================

    jal cw_clear_board

    la   $t0, board
    li   $t1, 1
    sb   $t1, 0($t0)       # Red pawn at square 1

    li   $a0, 1
    li   $a1, 0

    jal run_winner_test

    bne  $v0, $zero, cw1_pass_label

    li   $v0, 4
    la   $a0, cw1_fail
    syscall

    j cw2_test


cw1_pass_label:

    li   $v0, 4
    la   $a0, cw1_pass
    syscall


    # =================================================
    # W2: BLACK KING EXISTS
    #
    # Expected:
    # check_winner(3) = 0
    # =================================================

cw2_test:

    jal cw_clear_board

    la   $t0, board
    li   $t1, 4
    sb   $t1, 31($t0)      # Black king at square 32

    li   $a0, 3
    li   $a1, 0

    jal run_winner_test

    bne  $v0, $zero, cw2_pass_label

    li   $v0, 4
    la   $a0, cw2_fail
    syscall

    j cw3_test


cw2_pass_label:

    li   $v0, 4
    la   $a0, cw2_pass
    syscall


    # =================================================
    # W3: RED HAS BEEN ELIMINATED
    #
    # Black still has a pawn.
    #
    # Expected:
    # check_winner(1) = 1
    # =================================================

cw3_test:

    jal cw_clear_board

    la   $t0, board
    li   $t1, 3
    sb   $t1, 20($t0)      # Black pawn at square 21

    li   $a0, 1
    li   $a1, 1

    jal run_winner_test

    bne  $v0, $zero, cw3_pass_label

    li   $v0, 4
    la   $a0, cw3_fail
    syscall

    j cw4_test


cw3_pass_label:

    li   $v0, 4
    la   $a0, cw3_pass
    syscall


    # =================================================
    # W4: BLACK HAS BEEN ELIMINATED
    #
    # Red still has a king.
    #
    # Expected:
    # check_winner(3) = 1
    # =================================================

cw4_test:

    jal cw_clear_board

    la   $t0, board
    li   $t1, 2
    sb   $t1, 0($t0)       # Red king at square 1

    li   $a0, 3
    li   $a1, 1

    jal run_winner_test

    bne  $v0, $zero, cw4_pass_label

    li   $v0, 4
    la   $a0, cw4_fail
    syscall

    j cw5_test


cw4_pass_label:

    li   $v0, 4
    la   $a0, cw4_pass
    syscall


    # =================================================
    # W5: BOTH PLAYERS HAVE NO PIECES
    #
    # This is an artificial test configuration.
    #
    # Expected:
    # check_winner(1) = 1
    # check_winner(3) = 1
    # =================================================

cw5_test:

    jal cw_clear_board

    # Check Red

    li   $a0, 1
    li   $a1, 1

    jal run_winner_test

    beq  $v0, $zero, cw5_failed

    # Check Black

    li   $a0, 3
    li   $a1, 1

    jal run_winner_test

    beq  $v0, $zero, cw5_failed

    li   $v0, 4
    la   $a0, cw5_pass
    syscall

    j cw_tests_finished


cw5_failed:

    li   $v0, 4
    la   $a0, cw5_fail
    syscall


# =====================================================
# FINISH TESTING
# =====================================================

cw_tests_finished:

    li $v0, 4
    la $a0, cw_end
    syscall

    li $v0, 10
    syscall


# =====================================================
# HELPER: CLEAR BOARD
# =====================================================

cw_clear_board:

    la   $t0, board
    li   $t1, 0
    li   $t2, 32

cw_clear_loop:

    beq  $t1, $t2, cw_clear_done

    sb   $zero, 0($t0)

    addi $t0, $t0, 1
    addi $t1, $t1, 1

    j cw_clear_loop


cw_clear_done:

    jr $ra


# =====================================================
# HELPER: RUN ONE WINNER TEST
#
# $a0 = player to check
# $a1 = expected result
#
# $v0 = 1 if correct, 0 otherwise
# =====================================================

run_winner_test:

    addiu $sp, $sp, -8

    sw $s0, 0($sp)
    sw $ra, 4($sp)

    move $s0, $a1

    jal check_winner

    beq $v0, $s0, cw_test_pass

    li $v0, 0
    j cw_test_done


cw_test_pass:

    li $v0, 1


cw_test_done:

    lw $s0, 0($sp)
    lw $ra, 4($sp)

    addiu $sp, $sp, 8

    jr $ra


# =====================================================
# INCLUDE REQUIRED MODULES
# =====================================================

.include "../src/coordinates.asm"
.include "../src/board.asm"
.include "../src/game_control.asm"
