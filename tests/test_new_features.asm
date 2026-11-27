# ============================================================================
# TEST HARNESS: NEW FEATURES (ROTATION, MULTI-JUMP PATHS, INTERNATIONAL 10x10)
# Tests:
#   N1: 10x10 coordinates (square_to_coord & coord_to_square for 1..50)
#   N2: International init_board (20 Red, 10 Empty, 20 Black) + 180-deg rotation print
#   N3: International backward pawn capture (Black pawn jumps backward)
#   N4: International Flying King long-range normal move & obstruction check
#   N5: International Flying King long-range capture (multiple landing squares!)
#   N6: International Maximum Capture rule (2-piece chain overrides 1-piece jump)
#   N7: American promotion-ends-turn in max_capture_from (stops at king-row)
#   N8: Multi-jump capture path preview (print_capture_paths) + board immutability
# ============================================================================

.data
nt_title:   .asciiz "\n========== NEW FEATURES TEST SUITE ==========\n"
n1_pass:    .asciiz "N1: 10x10 coordinates (1..50 <-> row,col): PASS\n"
n1_fail:    .asciiz "N1: 10x10 coordinates (1..50 <-> row,col): FAIL\n"
n2_pass:    .asciiz "N2: International 10x10 init & 180-deg rotation: PASS\n"
n2_fail:    .asciiz "N2: International 10x10 init & 180-deg rotation: FAIL\n"
n3_pass:    .asciiz "N3: International backward pawn capture: PASS\n"
n3_fail:    .asciiz "N3: International backward pawn capture: FAIL\n"
n4_pass:    .asciiz "N4: International Flying King normal move: PASS\n"
n4_fail:    .asciiz "N4: International Flying King normal move: FAIL\n"
n5_pass:    .asciiz "N5: International Flying King multi-landing capture: PASS\n"
n5_fail:    .asciiz "N5: International Flying King multi-landing capture: FAIL\n"
n6_pass:    .asciiz "N6: International Maximum Capture rule: PASS\n"
n6_fail:    .asciiz "N6: International Maximum Capture rule: FAIL\n"
n7_pass:    .asciiz "N7: American promotion stops multi-jump depth: PASS\n"
n7_fail:    .asciiz "N7: American promotion stops multi-jump depth: FAIL\n"
n8_pass:    .asciiz "N8: Multi-jump capture path preview & immutability: PASS\n"
n8_fail:    .asciiz "N8: Multi-jump capture path preview & immutability: FAIL\n"
nt_fk_cap:  .asciiz "  [Flying King legal capture landings from 46] -> "
nt_paths:   .asciiz "  [Multi-jump capture paths from 21 (American)]:\n"
nt_nl:      .asciiz "\n"
nt_end:     .asciiz "========== NEW FEATURES TESTS FINISHED ==========\n"

.text
.globl main
main:
    li   $v0, 4
    la   $a0, nt_title
    syscall

    # ========================================================================
    # N1: 10x10 Coordinates
    #   sq 1 -> (0,1), sq 5 -> (0,9), sq 6 -> (1,0), sq 50 -> (9,8), sq 51 -> (-1,-1)
    # ========================================================================
    la   $t0, ruleset
    li   $t1, 1
    sw   $t1, 0($t0)
    jal  init_board

    li   $a0, 1
    jal  square_to_coord
    bne  $v0, $zero, n1_failed
    li   $t2, 1
    bne  $v1, $t2, n1_failed

    li   $a0, 5
    jal  square_to_coord
    bne  $v0, $zero, n1_failed
    li   $t2, 9
    bne  $v1, $t2, n1_failed

    li   $a0, 6
    jal  square_to_coord
    li   $t2, 1
    bne  $v0, $t2, n1_failed
    bne  $v1, $zero, n1_failed

    li   $a0, 50
    jal  square_to_coord
    li   $t2, 9
    bne  $v0, $t2, n1_failed
    li   $t2, 8
    bne  $v1, $t2, n1_failed

    li   $a0, 9
    li   $a1, 8
    jal  coord_to_square
    li   $t2, 50
    bne  $v0, $t2, n1_failed

    li   $a0, 51
    jal  square_to_coord
    li   $t2, -1
    bne  $v0, $t2, n1_failed

    li   $v0, 4
    la   $a0, n1_pass
    syscall
    j    n2_start

n1_failed:
    li   $v0, 4
    la   $a0, n1_fail
    syscall

    # ========================================================================
    # N2: International init_board counts (20 Red, 10 Empty, 20 Black) + Rotation
    # ========================================================================
n2_start:
    la   $t0, board
    lbu  $t1, 0($t0)            # sq 1 = 1 (Red)
    li   $t2, 1
    bne  $t1, $t2, n2_failed
    lbu  $t1, 19($t0)           # sq 20 = 1 (Red)
    bne  $t1, $t2, n2_failed
    lbu  $t1, 20($t0)           # sq 21 = 0 (Empty)
    bne  $t1, $zero, n2_failed
    lbu  $t1, 29($t0)           # sq 30 = 0 (Empty)
    bne  $t1, $zero, n2_failed
    lbu  $t1, 30($t0)           # sq 31 = 3 (Black)
    li   $t2, 3
    bne  $t1, $t2, n2_failed
    lbu  $t1, 49($t0)           # sq 50 = 3 (Black)
    bne  $t1, $t2, n2_failed

    # Print rotated Red view of 10x10 board (visual sanity check)
    la   $t0, current_player
    li   $t1, 1
    sw   $t1, 0($t0)
    jal  print_board

    li   $v0, 4
    la   $a0, n2_pass
    syscall
    j    n3_start

n2_failed:
    li   $v0, 4
    la   $a0, n2_fail
    syscall

    # ========================================================================
    # N3: International Backward Pawn Capture
    #   10x10: Black pawn at sq 18 (row 3, col 4)
    #          Red pawn   at sq 23 (row 4, col 5)
    #          Empty      at sq 29 (row 5, col 6) -> backward jump (+2, +2)!
    # ========================================================================
n3_start:
    jal  nt_clear_board
    la   $t0, board
    li   $t1, 3
    sb   $t1, 17($t0)           # sq 18 = Black pawn
    li   $t1, 1
    sb   $t1, 22($t0)           # sq 23 = Red pawn

    li   $a0, 18
    li   $a1, 29
    li   $a2, 3
    jal  validate_capture
    li   $t2, 1
    bne  $v0, $t2, n3_failed

    li   $v0, 4
    la   $a0, n3_pass
    syscall
    j    n4_start

n3_failed:
    li   $v0, 4
    la   $a0, n3_fail
    syscall

    # ========================================================================
    # N4: International Flying King Normal Move (long diagonal + blocked check)
    #   10x10: Black King at sq 46 (row 9, col 0)
    #          Diagonal NE: (8,1)=41, (7,2)=37, (6,3)=32, (5,4)=28, (4,5)=23, (3,6)=19
    #          Empty board -> 46 -> 19 is VALID (distance 6).
    #          Place obstacle at 32 -> 46 -> 19 is INVALID, 46 -> 37 is VALID.
    # ========================================================================
n4_start:
    jal  nt_clear_board
    la   $t0, board
    li   $t1, 4
    sb   $t1, 45($t0)           # sq 46 = Black King

    li   $a0, 46
    li   $a1, 19
    li   $a2, 3
    jal  validate_normal_move
    li   $t2, 1
    bne  $v0, $t2, n4_failed

    # Place obstacle at sq 32
    la   $t0, board
    li   $t1, 3
    sb   $t1, 31($t0)           # sq 32 = Black pawn blocking

    li   $a0, 46
    li   $a1, 19
    li   $a2, 3
    jal  validate_normal_move
    bne  $v0, $zero, n4_failed

    li   $a0, 46
    li   $a1, 37
    li   $a2, 3
    jal  validate_normal_move
    li   $t2, 1
    bne  $v0, $t2, n4_failed

    li   $v0, 4
    la   $a0, n4_pass
    syscall
    j    n5_start

n4_failed:
    li   $v0, 4
    la   $a0, n4_fail
    syscall

    # ========================================================================
    # N5: International Flying King Capture with Multiple Landing Squares
    #   Black King at sq 46 (9,0), Red pawn at sq 37 (7,2), Red pawn at sq 14 (2,7)
    #   Along NE ray from 46: 41(empty), 37(Red), 32(empty), 28(empty), 23(empty), 19(empty), 14(Red)
    #   Valid landings over 37: 32, 28, 23, 19 (4 landing squares!) -> 14 and beyond invalid!
    # ========================================================================
n5_start:
    jal  nt_clear_board
    la   $t0, board
    li   $t1, 4
    sb   $t1, 45($t0)           # sq 46 = Black King
    li   $t1, 1
    sb   $t1, 36($t0)           # sq 37 = Red pawn
    sb   $t1, 13($t0)           # sq 14 = Red pawn (blocks further ray)

    li   $v0, 4
    la   $a0, nt_fk_cap
    syscall
    li   $a0, 46
    li   $a1, 3
    jal  print_capture_moves
    move $s0, $v0
    li   $v0, 4
    la   $a0, nt_nl
    syscall

    li   $t2, 4                 # Expect 4 valid landing squares: 32 28 23 19
    bne  $s0, $t2, n5_failed

    li   $v0, 4
    la   $a0, n5_pass
    syscall
    j    n6_start

n5_failed:
    li   $v0, 4
    la   $a0, n5_fail
    syscall

    # ========================================================================
    # N6: International Maximum Capture Rule
    #   Black pawn at sq 38 (row 7, col 4):
    #     - NW jump over Red at 32 (6,3) -> 27 (5,2): only 1 capture
    #     - NE jump over Red at 33 (6,5) -> 29 (5,6), then NW over Red at 23 (4,5) -> 18 (3,4): 2 captures!
    #   Expected:
    #     max_capture_from(38, 3) == 2
    #     is_capture_allowed(38, 27, 3) == 0 (blocked by max-capture rule!)
    #     is_capture_allowed(38, 29, 3) == 1 (achieves max capture = 2!)
    # ========================================================================
n6_start:
    jal  nt_clear_board
    la   $t0, board
    li   $t1, 3
    sb   $t1, 37($t0)           # sq 38 = Black pawn
    li   $t1, 1
    sb   $t1, 31($t0)           # sq 32 = Red pawn (1-capture branch)
    sb   $t1, 32($t0)           # sq 33 = Red pawn (2-capture branch hop 1)
    sb   $t1, 22($t0)           # sq 23 = Red pawn (2-capture branch hop 2)

    li   $a0, 38
    li   $a1, 3
    jal  max_capture_from
    li   $t2, 2
    bne  $v0, $t2, n6_failed

    li   $a0, 38
    li   $a1, 27
    li   $a2, 3
    jal  is_capture_allowed
    bne  $v0, $zero, n6_failed  # Must reject 1-capture hop when 2-capture exists

    li   $a0, 38
    li   $a1, 29
    li   $a2, 3
    jal  is_capture_allowed
    li   $t2, 1
    bne  $v0, $t2, n6_failed    # Must allow 2-capture hop

    li   $v0, 4
    la   $a0, n6_pass
    syscall
    j    n7_start

n6_failed:
    li   $v0, 4
    la   $a0, n6_fail
    syscall

    # ========================================================================
    # N7: American Checkers Promotion Ends Turn Immediately
    #   8x8: Black pawn at sq 10 (2,3) jumps Red at sq 6 (1,2) -> sq 1 (0,1, king-row!)
    #        Even if Red is at sq 5 (1,0) and empty at ... wait: from sq 1 (0,1),
    #        (1,2) is 6 (just captured), (1,0) is 5 (no landing behind col 0).
    #        Better: Black pawn at sq 11 (2,5) jumps Red at sq 7 (1,4) -> sq 2 (0,3, king-row!)
    #        Place another Red at sq 6 (1,2) with sq 9 (2,1) empty.
    #        In American mode, pawn reaching sq 2 promotes and turn ENDS -> max_capture_from == 1!
    # ========================================================================
n7_start:
    la   $t0, ruleset
    sw   $zero, 0($t0)          # Switch to American 8x8
    jal  init_board
    jal  nt_clear_board

    la   $t0, board
    li   $t1, 3
    sb   $t1, 10($t0)           # sq 11 (2,5) = Black pawn
    li   $t1, 1
    sb   $t1, 6($t0)            # sq 7  (1,4) = Red pawn -> jump to sq 2 (0,3)
    sb   $t1, 5($t0)            # sq 6  (1,2) = Red pawn -> would be backward jump 2->9 if allowed

    li   $a0, 11
    li   $a1, 3
    jal  max_capture_from
    li   $t2, 1                 # Must be 1 (turn stops at king-row sq 2)
    bne  $v0, $t2, n7_failed

    li   $v0, 4
    la   $a0, n7_pass
    syscall
    j    n8_start

n7_failed:
    li   $v0, 4
    la   $a0, n7_fail
    syscall

    # ========================================================================
    # N8: Multi-Jump Capture Path Preview (American 8x8) & Board Immutability
    #   Black pawn at sq 21 (5,0) -> Red at 17 (4,1) -> land 14 (3,2)
    #   From 14 (3,2):
    #     - Red at 9  (2,1) -> land 5 (1,0)  => 21x14x5
    #     - Red at 10 (2,3) -> land 7 (1,4)  => 21x14x7
    # ========================================================================
n8_start:
    jal  nt_clear_board
    la   $t0, board
    li   $t1, 3
    sb   $t1, 20($t0)           # sq 21 = Black pawn
    li   $t1, 1
    sb   $t1, 16($t0)           # sq 17 = Red pawn
    sb   $t1, 8($t0)            # sq 9  = Red pawn
    sb   $t1, 9($t0)            # sq 10 = Red pawn

    li   $v0, 4
    la   $a0, nt_paths
    syscall
    li   $a0, 21
    li   $a1, 3
    jal  print_capture_paths

    # Verify board was completely restored after DFS!
    la   $t0, board
    lbu  $t1, 20($t0)
    li   $t2, 3
    bne  $t1, $t2, n8_failed
    lbu  $t1, 16($t0)
    li   $t2, 1
    bne  $t1, $t2, n8_failed
    lbu  $t1, 8($t0)
    bne  $t1, $t2, n8_failed
    lbu  $t1, 9($t0)
    bne  $t1, $t2, n8_failed
    lbu  $t1, 13($t0)
    bne  $t1, $zero, n8_failed

    li   $v0, 4
    la   $a0, n8_pass
    syscall
    j    nt_done

n8_failed:
    li   $v0, 4
    la   $a0, n8_fail
    syscall

nt_done:
    li   $v0, 4
    la   $a0, nt_end
    syscall
    li   $v0, 10
    syscall

nt_clear_board:
    la   $t0, board
    la   $t3, captured_mask
    li   $t1, 0
    li   $t2, 50
ntcb_loop:
    beq  $t1, $t2, ntcb_done
    sb   $zero, 0($t0)
    sb   $zero, 0($t3)
    addiu $t0, $t0, 1
    addiu $t3, $t3, 1
    addiu $t1, $t1, 1
    j    ntcb_loop
ntcb_done:
    jr   $ra

.include "../src/board.asm"
.include "../src/coordinates.asm"
.include "../src/movement.asm"
.include "../src/promotion.asm"
.include "../src/capture.asm"
.include "../src/game_control.asm"
