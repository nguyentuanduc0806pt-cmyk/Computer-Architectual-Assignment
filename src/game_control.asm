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

.data
gc_black_turn_msg:  .asciiz "\n=== BLACK's Turn (b / B) ===\n"
gc_red_turn_msg:    .asciiz "\n=== RED's Turn (r / R) ===\n"
gc_prompt_start:    .asciiz "Enter starting square (1-32): "
gc_prompt_dest:     .asciiz "Enter destination square (1-32): "
gc_black_wins_msg:  .asciiz "\n==============================\n   GAME OVER: BLACK WINS!\n==============================\n"
gc_red_wins_msg:    .asciiz "\n==============================\n   GAME OVER: RED WINS!\n==============================\n"

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

# ============================================================================
# PRINT TURN BANNER
# Reads global current_player and prints whose turn it is.
# ============================================================================
.globl print_turn_banner
print_turn_banner:
    la   $t0, current_player     # $t0 = address of shared global current_player
    lw   $t1, 0($t0)             # $t1 = value (3 = Black, 1 = Red)

    li   $t2, 3                  # $t2 = 3 (Black player code)
    beq  $t1, $t2, gc_print_black

    la   $a0, gc_red_turn_msg    # Otherwise, it's Red's turn
    j    gc_print_turn_out

gc_print_black:
    la   $a0, gc_black_turn_msg  # Load Black's turn banner string

gc_print_turn_out:
    li   $v0, 4                  # Syscall 4 = print_string
    syscall
    jr   $ra                     # Leaf procedure (no jal) -> no stack needed

# ============================================================================
# READ PLAYER MOVE
# Prompts user for start and destination squares, stores them in shared
# globals (start_square, destination), and also returns them in ($v0, $v1).
# Output: $v0 = start_square, $v1 = destination
# ============================================================================
.globl read_player_move
read_player_move:
    # 1. Prompt and read starting square
    li   $v0, 4                  # Syscall 4: print_string
    la   $a0, gc_prompt_start
    syscall

    li   $v0, 5                  # Syscall 5: read_int -> result lands in $v0
    syscall
    move $t0, $v0                # Save start in $t0 (next syscall overwrites $v0)

    la   $t2, start_square       # Store into shared global start_square
    sw   $t0, 0($t2)             # (Required by plan.md Section 3.2)

    # 2. Prompt and read destination square
    li   $v0, 4
    la   $a0, gc_prompt_dest
    syscall

    li   $v0, 5                  # Syscall 5: read_int -> result lands in $v0
    syscall
    move $t1, $v0                # Save destination in $t1

    la   $t2, destination        # Store into shared global destination
    sw   $t1, 0($t2)

    # 3. Return both values to caller
    move $v0, $t0                # $v0 = start_square
    move $v1, $t1                # $v1 = destination
    jr   $ra

# ============================================================================
# SWITCH PLAYER
# Toggles global current_player between 3 (Black) and 1 (Red).
# ============================================================================
.globl switch_player
switch_player:
    la   $t0, current_player     # $t0 = address of current_player
    lw   $t1, 0($t0)             # $t1 = current value (1 or 3)

    li   $t2, 3                  # Is it currently Black (3)?
    beq  $t1, $t2, gc_set_red

    li   $t1, 3                  # Otherwise it was Red (1) -> switch to Black (3)
    j    gc_store_player

gc_set_red:
    li   $t1, 1                  # Switch to Red (1)

gc_store_player:
    sw   $t1, 0($t0)             # Write updated player back to memory
    jr   $ra

# ============================================================================
# ANNOUNCE WINNER
# Input:  $a0 = winning player (1 = Red, 3 = Black)
# Effect: Sets global game_over = 1 and prints the winner announcement.
# ============================================================================
.globl announce_winner
announce_winner:
    # 1. Mark game_over = 1 in shared global state
    la   $t0, game_over
    li   $t1, 1
    sw   $t1, 0($t0)

    # 2. Pick the matching winner message
    li   $t2, 3
    beq  $a0, $t2, gc_black_won

    la   $a0, gc_red_wins_msg    # Winner is Red (1)
    j    gc_print_winner

gc_black_won:
    la   $a0, gc_black_wins_msg  # Winner is Black (3)

gc_print_winner:
    li   $v0, 4                  # Syscall 4: print_string
    syscall
    jr   $ra