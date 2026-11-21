# ============================================================================
# GAME CONTROL HELPERS
# Owner: Member B
# main.asm owns the entry point and overall game loop.
# ============================================================================


# ============================================================================
# CHECK WINNER
# Owner: Member B
#
# Input:
#   $a0 = player to check
#         1 = Red
#         3 = Black
#
# Output:
#   $v0 = 1  -> Player has no remaining pieces
#   $v0 = 0  -> Player still has at least one piece
#   $v0 = -1 -> Invalid player
#
# Board encoding:
#   0 = Empty
#   1 = Red pawn
#   2 = Red king
#   3 = Black pawn
#   4 = Black king
#
# This procedure does NOT modify the board.
# ============================================================================

.text
.globl check_winner

check_winner:

    # ------------------------------------------------
    # 1. Determine which player's pieces to search for
    # ------------------------------------------------

    li   $t0, 1
    beq  $a0, $t0, cw_check_red

    li   $t0, 3
    beq  $a0, $t0, cw_check_black

    # Invalid player argument

    li   $v0, -1
    jr   $ra


    # ------------------------------------------------
    # 2. Search for Red pieces
    #
    # Red pawn = 1
    # Red king = 2
    # ------------------------------------------------

cw_check_red:

    li   $t5, 1
    li   $t6, 2

    j cw_start_scan


    # ------------------------------------------------
    # 3. Search for Black pieces
    #
    # Black pawn = 3
    # Black king = 4
    # ------------------------------------------------

cw_check_black:

    li   $t5, 3
    li   $t6, 4


    # ------------------------------------------------
    # 4. Scan all 32 playable squares
    # ------------------------------------------------

cw_start_scan:

    la   $t1, board

    li   $t2, 0              # Array index
    li   $t3, 32             # Number of squares


cw_scan_loop:

    # Stop after checking all 32 squares

    beq  $t2, $t3, cw_no_pieces

    # Load current piece

    lbu  $t4, 0($t1)

    # Check for player's pawn

    beq  $t4, $t5, cw_has_piece

    # Check for player's king

    beq  $t4, $t6, cw_has_piece

    # Move to next array position

    addiu $t1, $t1, 1
    addiu $t2, $t2, 1

    j cw_scan_loop


    # ------------------------------------------------
    # 5. At least one piece found
    # ------------------------------------------------

cw_has_piece:

    li $v0, 0

    jr $ra


    # ------------------------------------------------
    # 6. No pieces found after scanning the entire board
    # ------------------------------------------------

cw_no_pieces:

    li $v0, 1

    jr $ra
