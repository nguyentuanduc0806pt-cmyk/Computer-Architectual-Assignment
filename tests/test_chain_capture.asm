
# ============================================================================
# MEMBER B - CHAIN CAPTURE TEST
#
# Initial state is AFTER the first capture:
#
# Black pawn: square 14
# Red pawn:   square 10
# Empty:      square 7
#
# Next capture required:
# 14 -> 7
#
# After entering 7:
# Square 14 = Empty
# Square 10 = Empty
# Square 7  = Black pawn
# ============================================================================

.data

chain_test_title:
    .asciiz "\n========== CHAIN CAPTURE TEST ==========\n"

chain_test_pass:
    .asciiz "\nCHAIN TEST: Both captures completed correctly: PASS\n"

chain_test_fail:
    .asciiz "\nCHAIN TEST: Board update incorrect: FAIL\n"

chain_test_error:
    .asciiz "\nCHAIN TEST: Procedure returned failure.\n"

.text
.globl main

main:

    # ------------------------------------------------
    # 1. Clear board
    # ------------------------------------------------

    jal test_clear_board

    # ------------------------------------------------
    # 2. Set current player to Black
    # ------------------------------------------------

    la   $t0, current_player

    li   $t1, 3
    sw   $t1, 0($t0)

    # ------------------------------------------------
    # 3. Set up chain capture position
    # ------------------------------------------------

    la   $t0, board

    li   $t1, 3
    sb   $t1, 13($t0)       # Square 14: Black pawn

    li   $t1, 1
    sb   $t1, 9($t0)        # Square 10: Red pawn

    # Square 7 remains empty.

    # ------------------------------------------------
    # 4. Display test title
    # ------------------------------------------------

    li   $v0, 4
    la   $a0, chain_test_title
    syscall

    # ------------------------------------------------
    # 5. Start chain capture from square 14
    # ------------------------------------------------

    li   $a0, 14

    jal chain_capture

    # Check procedure result

    beq  $v0, $zero, chain_test_failed


    # ------------------------------------------------
    # 6. Verify starting square is empty
    # ------------------------------------------------

    la   $t0, board

    lbu  $t1, 13($t0)

    bne  $t1, $zero, chain_test_failed


    # ------------------------------------------------
    # 7. Verify captured Red piece was removed
    # ------------------------------------------------

    lbu  $t1, 9($t0)

    bne  $t1, $zero, chain_test_failed


    # ------------------------------------------------
    # 8. Verify Black pawn reached square 7
    # ------------------------------------------------

    lbu  $t1, 6($t0)

    li   $t2, 3

    bne  $t1, $t2, chain_test_failed


    # ------------------------------------------------
    # 9. Test passed
    # ------------------------------------------------

    li   $v0, 4
    la   $a0, chain_test_pass
    syscall

    j chain_test_exit


chain_test_failed:

    li   $v0, 4
    la   $a0, chain_test_fail
    syscall


chain_test_exit:

    li $v0, 10
    syscall


# =====================================================
# HELPER: CLEAR BOARD
# =====================================================

test_clear_board:

    la   $t0, board
    li   $t1, 0
    li   $t2, 32

test_clear_loop:

    beq  $t1, $t2, test_clear_done

    sb   $zero, 0($t0)

    addi $t0, $t0, 1
    addi $t1, $t1, 1

    j test_clear_loop

test_clear_done:

    jr $ra


# =====================================================
# INCLUDE REQUIRED MODULES
# =====================================================

.include "../src/board.asm"
.include "../src/coordinates.asm"
.include "../src/promotion.asm"
.include "../src/capture.asm"
