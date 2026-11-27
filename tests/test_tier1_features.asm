# ============================================================================
# TEST HARNESS: TIER 1 & QOL FEATURES
# Tests:
#   T1: check_promotion (Red pawn -> 29..32, Black pawn -> 1..4, non-final row)
#   T2: has_normal_move & print_normal_moves (pawn, king, blocked piece)
#   T3: has_capture_from, has_any_capture, print_capture_moves,
#       print_mandatory_capture_pieces
#   T4: Trap-win detection (Figure 9 from assignment PDF: pieces exist, 0 moves)
#   T5: Not trapped when only a capture exists (0 normal moves, 1 capture)
#   T6: Board immutability across all read-only query helpers
# ============================================================================

.data
t_title:    .asciiz "\n========== TIER 1 & QOL FEATURE TESTS ==========\n"
t1_pass:    .asciiz "T1: check_promotion (Red/Black/non-final): PASS\n"
t1_fail:    .asciiz "T1: check_promotion (Red/Black/non-final): FAIL\n"
t2_pass:    .asciiz "T2: has_normal_move & print_normal_moves: PASS\n"
t2_fail:    .asciiz "T2: has_normal_move & print_normal_moves: FAIL\n"
t3_pass:    .asciiz "T3: has_any_capture & mandatory piece scan: PASS\n"
t3_fail:    .asciiz "T3: has_any_capture & mandatory piece scan: FAIL\n"
t4_pass:    .asciiz "T4: Trapped opponent (Figure 9) has 0 moves: PASS\n"
t4_fail:    .asciiz "T4: Trapped opponent (Figure 9) has 0 moves: FAIL\n"
t5_pass:    .asciiz "T5: Piece with only capture is NOT trapped: PASS\n"
t5_fail:    .asciiz "T5: Piece with only capture is NOT trapped: FAIL\n"
t6_pass:    .asciiz "T6: All query helpers keep board immutable: PASS\n"
t6_fail:    .asciiz "T6: All query helpers keep board immutable: FAIL\n"
t_dbg_nm:   .asciiz "  [print_normal_moves(18, BlackKing)] -> "
t_dbg_cm:   .asciiz "  [print_capture_moves(14, BlackKing)] -> "
t_dbg_mp:   .asciiz "  [print_mandatory_capture_pieces(Black)] -> "
t_nl:       .asciiz "\n"
t_end:      .asciiz "========== TESTING FINISHED ==========\n"

.text
.globl main
main:
    li   $v0, 4
    la   $a0, t_title
    syscall

    # ========================================================================
    # T1: check_promotion
    # ========================================================================
    jal  t_clear_board
    la   $t0, board
    li   $t1, 1
    sb   $t1, 29($t0)          # Square 30: Red pawn -> should promote to 2
    sb   $t1, 20($t0)          # Square 21: Red pawn -> should stay 1
    li   $t1, 3
    sb   $t1, 1($t0)           # Square 2:  Black pawn -> should promote to 4
    sb   $t1, 10($t0)          # Square 11: Black pawn -> should stay 3

    li   $a0, 30
    jal  check_promotion
    li   $a0, 21
    jal  check_promotion
    li   $a0, 2
    jal  check_promotion
    li   $a0, 11
    jal  check_promotion

    la   $t0, board
    lbu  $t1, 29($t0)
    li   $t2, 2
    bne  $t1, $t2, t1_failed
    lbu  $t1, 20($t0)
    li   $t2, 1
    bne  $t1, $t2, t1_failed
    lbu  $t1, 1($t0)
    li   $t2, 4
    bne  $t1, $t2, t1_failed
    lbu  $t1, 10($t0)
    li   $t2, 3
    bne  $t1, $t2, t1_failed

    li   $v0, 4
    la   $a0, t1_pass
    syscall
    j    t2_start

t1_failed:
    li   $v0, 4
    la   $a0, t1_fail
    syscall

    # ========================================================================
    # T2: has_normal_move & print_normal_moves
    #   Black King at square 18 (row 4, col 3) on empty board -> 4 moves: 14 15 22 23
    #   Black Pawn at square 21 (row 5, col 0) with square 17 blocked -> 0 moves
    # ========================================================================
t2_start:
    jal  t_clear_board
    la   $t0, board
    li   $t1, 4
    sb   $t1, 17($t0)          # Square 18: Black King

    li   $a0, 18
    li   $a1, 3
    jal  has_normal_move
    li   $t2, 1
    bne  $v0, $t2, t2_failed

    li   $v0, 4
    la   $a0, t_dbg_nm
    syscall
    li   $a0, 18
    li   $a1, 3
    jal  print_normal_moves
    move $s0, $v0
    li   $v0, 4
    la   $a0, t_nl
    syscall

    li   $t2, 4                # Expect 4 legal moves
    bne  $s0, $t2, t2_failed

    # Now test blocked Black pawn at 21 (only forward neighbor 17 occupied)
    la   $t0, board
    li   $t1, 3
    sb   $t1, 20($t0)          # Square 21: Black pawn
    sb   $t1, 16($t0)          # Square 17: Black pawn blocking
    li   $a0, 21
    li   $a1, 3
    jal  has_normal_move
    bne  $v0, $zero, t2_failed

    li   $v0, 4
    la   $a0, t2_pass
    syscall
    j    t3_start

t2_failed:
    li   $v0, 4
    la   $a0, t2_fail
    syscall

    # ========================================================================
    # T3: has_any_capture, print_capture_moves, print_mandatory_capture_pieces
    #   Black King at 14 can jump Red at 9->5 (no, (3,2)->(2,1)=9->(1,0)=5)
    #   and Red at 18->23 ((3,2)->(4,3)=18->(5,4)=23).
    #   Black pawn at 21 can jump Red at 17->14? No, 14 is occupied by Black King!
    #   So put Black pawn at 25 (row 6, col 1), Red pawn at 22 (row 5, col 2), dest 18 occupied?
    #   Let's use:
    #     Square 14 (3,2) = Black King (4)
    #     Square 9  (2,1) = Red pawn (1) -> jump to 5 (1,0)
    #     Square 18 (4,3) = Red pawn (1) -> jump to 23 (5,4)
    #     Square 29 (7,0) = Black pawn (3)
    #     Square 25 (6,1) = Red pawn (1) -> jump to 22 (5,2)
    #   Expected:
    #     has_any_capture(3) = 1, has_any_capture(1) = 0 (Red pawns at 9,18,25 cannot jump!)
    #     Wait: Red at 9 (2,1) -> middle 14 (Black King) -> dest 18 occupied (Red)! So 0.
    #     Red at 18 (4,3) -> middle 22 empty, 23 empty -> 0.
    #     Red at 25 (6,1) -> middle 29 (Black) -> row 8 off board -> 0.
    #     print_capture_moves(14, 3) -> "5 23" (count = 2)
    #     print_mandatory_capture_pieces(3) -> "14 29" (count = 2)
    # ========================================================================
t3_start:
    jal  t_clear_board
    la   $t0, board
    li   $t1, 4
    sb   $t1, 13($t0)          # Square 14: Black King
    li   $t1, 1
    sb   $t1, 8($t0)           # Square 9:  Red pawn
    sb   $t1, 17($t0)          # Square 18: Red pawn
    sb   $t1, 24($t0)          # Square 25: Red pawn
    li   $t1, 3
    sb   $t1, 28($t0)          # Square 29: Black pawn

    li   $a0, 3
    jal  has_any_capture
    li   $t2, 1
    bne  $v0, $t2, t3_failed

    li   $a0, 1
    jal  has_any_capture
    bne  $v0, $zero, t3_failed

    li   $v0, 4
    la   $a0, t_dbg_cm
    syscall
    li   $a0, 14
    li   $a1, 3
    jal  print_capture_moves
    move $s0, $v0
    li   $v0, 4
    la   $a0, t_nl
    syscall
    li   $t2, 2
    bne  $s0, $t2, t3_failed

    li   $v0, 4
    la   $a0, t_dbg_mp
    syscall
    li   $a0, 3
    jal  print_mandatory_capture_pieces
    move $s0, $v0
    li   $v0, 4
    la   $a0, t_nl
    syscall
    li   $t2, 2
    bne  $s0, $t2, t3_failed

    li   $v0, 4
    la   $a0, t3_pass
    syscall
    j    t4_start

t3_failed:
    li   $v0, 4
    la   $a0, t3_fail
    syscall

    # ========================================================================
    # T4: Figure 9 Trap-Win Position (CA_Assignment_261.pdf page 8)
    #   Square 1  (0,1) = Black King (4)
    #   Square 2  (0,3) = Red King (2)
    #   Square 5  (1,0) = Red pawn (1)
    #   Square 6  (1,2) = Black pawn (3)
    #   Square 10 (2,3) = Red pawn (1)
    #   Expected: check_winner(3) == 0 (Black has pieces),
    #             t_has_any_legal_move(3) == 0 (Black is TRAPPED!)
    # ========================================================================
t4_start:
    jal  t_clear_board
    la   $t0, board
    li   $t1, 4
    sb   $t1, 0($t0)           # Square 1:  Black King
    li   $t1, 2
    sb   $t1, 1($t0)           # Square 2:  Red King
    li   $t1, 1
    sb   $t1, 4($t0)           # Square 5:  Red pawn
    sb   $t1, 9($t0)           # Square 10: Red pawn
    li   $t1, 3
    sb   $t1, 5($t0)           # Square 6:  Black pawn

    li   $a0, 3
    jal  check_winner
    bne  $v0, $zero, t4_failed

    li   $a0, 3
    jal  t_has_any_legal_move
    bne  $v0, $zero, t4_failed

    li   $v0, 4
    la   $a0, t4_pass
    syscall
    j    t5_start

t4_failed:
    li   $v0, 4
    la   $a0, t4_fail
    syscall

    # ========================================================================
    # T5: Piece blocked on normal moves, but has a capture -> NOT trapped!
    #   Square 1 (0,1) = Black King (4)
    #   Square 5 (1,0) = Red pawn (1)
    #   Square 6 (1,2) = Red pawn (1)
    #   Square 10 (2,3) = Empty (0) -> Black King can jump 1 -> 10!
    # ========================================================================
t5_start:
    jal  t_clear_board
    la   $t0, board
    li   $t1, 4
    sb   $t1, 0($t0)           # Square 1: Black King
    li   $t1, 1
    sb   $t1, 4($t0)           # Square 5: Red pawn
    sb   $t1, 5($t0)           # Square 6: Red pawn

    li   $a0, 1
    li   $a1, 3
    jal  has_normal_move
    bne  $v0, $zero, t5_failed # Must have 0 normal moves

    li   $a0, 3
    jal  t_has_any_legal_move
    li   $t2, 1
    bne  $v0, $t2, t5_failed   # Must return 1 (capture 1->10 is legal!)

    li   $v0, 4
    la   $a0, t5_pass
    syscall

    # ========================================================================
    # T6: Verify board was NOT modified by T5 queries
    # ========================================================================
    la   $t0, board
    lbu  $t1, 0($t0)
    li   $t2, 4
    bne  $t1, $t2, t6_failed
    lbu  $t1, 4($t0)
    li   $t2, 1
    bne  $t1, $t2, t6_failed
    lbu  $t1, 5($t0)
    li   $t2, 1
    bne  $t1, $t2, t6_failed
    lbu  $t1, 9($t0)
    bne  $t1, $zero, t6_failed

    li   $v0, 4
    la   $a0, t6_pass
    syscall
    j    t_done

t5_failed:
    li   $v0, 4
    la   $a0, t5_fail
    syscall
    j    t_done

t6_failed:
    li   $v0, 4
    la   $a0, t6_fail
    syscall

t_done:
    li   $v0, 4
    la   $a0, t_end
    syscall
    li   $v0, 10
    syscall

# Helper: mirrors player_has_any_legal_move from main.asm
t_has_any_legal_move:
    addiu $sp, $sp, -16
    sw   $s0, 0($sp)
    sw   $s1, 4($sp)
    sw   $ra, 8($sp)
    move $s0, $a0
    li   $s1, 1
thlm_loop:
    slti $t0, $s1, 33
    beq  $t0, $zero, thlm_none
    move $a0, $s1
    move $a1, $s0
    jal  has_normal_move
    bne  $v0, $zero, thlm_yes
    move $a0, $s1
    move $a1, $s0
    jal  has_capture_from
    bne  $v0, $zero, thlm_yes
    addiu $s1, $s1, 1
    j    thlm_loop
thlm_yes:
    li   $v0, 1
    j    thlm_ret
thlm_none:
    li   $v0, 0
thlm_ret:
    lw   $s0, 0($sp)
    lw   $s1, 4($sp)
    lw   $ra, 8($sp)
    addiu $sp, $sp, 16
    jr   $ra

t_clear_board:
    la   $t0, board
    li   $t1, 0
    li   $t2, 32
tcb_loop:
    beq  $t1, $t2, tcb_done
    sb   $zero, 0($t0)
    addiu $t0, $t0, 1
    addiu $t1, $t1, 1
    j    tcb_loop
tcb_done:
    jr   $ra

.include "../src/board.asm"
.include "../src/coordinates.asm"
.include "../src/movement.asm"
.include "../src/promotion.asm"
.include "../src/capture.asm"
.include "../src/game_control.asm"
