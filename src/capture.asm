# ============================================================================
# CAPTURE VALIDATION, EXECUTION, AND CHAIN CAPTURES
# Owner: Member B
# A chain capture must continue while another capture is available.
# Promotion during a capture must happen immediately so a new king can capture
# backwards in the same chain.
# ============================================================================
.data

.align 2
cap_dr: .word -2, -2,  2,  2
cap_dc: .word -2,  2, -2,  2

chain_avail_msg:
    .asciiz "Available chain landing squares: "

chain_prompt_msg:
    .asciiz "Chaining possible. Enter landing square: "

chain_invalid_msg:
    .asciiz "Not a valid capture! Try another landing square.\n"

chain_finished_msg:
    .asciiz "No further capture available. Chain complete.\n"

cap_fb_red_msg:
    .asciiz "Captured Red's piece! ("

cap_fb_black_msg:
    .asciiz "Captured Black's piece! ("

cap_fb_close_msg:
    .asciiz ")\n"

chain_promo_pre_msg:
    .asciiz "Promoted to King at square "

chain_promo_post_msg:
    .asciiz "!\n"

.text
.globl validate_capture
validate_capture:

# ============================================================================
# CAPTURE VALIDATION
# Owner: Member B
#
# Input:
#   $a0 = starting square (1-32)
#   $a1 = destination square (1-32)
#   $a2 = current player (1=Red, 3=Black)
#
# Output:
#   $v0 = 1 if capture is valid
#   $v0 = 0 if capture is invalid
#
# IMPORTANT: This procedure does NOT modify board memory.
# ============================================================================

    # ------------------------------------------------
    # 1. Save registers
    # ------------------------------------------------

    addiu $sp, $sp, -40

    sw $s0, 0($sp)
    sw $s1, 4($sp)
    sw $s2, 8($sp)
    sw $s3, 12($sp)
    sw $s4, 16($sp)
    sw $s5, 20($sp)
    sw $s6, 24($sp)
    sw $s7, 28($sp)
    sw $ra, 32($sp)

    # Preserve input arguments
    move $s0, $a0       # Starting square
    move $s1, $a1       # Destination square
    move $s2, $a2       # Current player

    # ------------------------------------------------
    # 2. Validate square number ranges
    # ------------------------------------------------

    slti $t0, $s0, 1
    bne  $t0, $zero, vc_invalid

    slti $t0, $s0, 33
    beq  $t0, $zero, vc_invalid

    slti $t0, $s1, 1
    bne  $t0, $zero, vc_invalid

    slti $t0, $s1, 33
    beq  $t0, $zero, vc_invalid

    # ------------------------------------------------
    # 3. Validate current player
    # ------------------------------------------------

    li   $t0, 1
    beq  $s2, $t0, vc_check_red_piece

    li   $t0, 3
    beq  $s2, $t0, vc_check_black_piece

    j vc_invalid


    # ------------------------------------------------
    # 4. Check starting piece ownership
    # ------------------------------------------------

vc_check_red_piece:

    la   $t0, board
    addiu $t1, $s0, -1
    addu $t0, $t0, $t1

    lbu  $s3, 0($t0)

    # Red can move piece 1 or 2
    li   $t0, 1
    beq  $s3, $t0, vc_owner_valid

    li   $t0, 2
    bne  $s3, $t0, vc_invalid

    j vc_owner_valid


vc_check_black_piece:

    la   $t0, board
    addiu $t1, $s0, -1
    addu $t0, $t0, $t1

    lbu  $s3, 0($t0)

    # Black can move piece 3 or 4
    li   $t0, 3
    beq  $s3, $t0, vc_owner_valid

    li   $t0, 4
    bne  $s3, $t0, vc_invalid


vc_owner_valid:

    # ------------------------------------------------
    # 5. Check whether destination is empty
    # ------------------------------------------------

    la   $t0, board

    addiu $t1, $s1, -1
    addu  $t0, $t0, $t1

    lbu  $t1, 0($t0)

    # Destination must be empty
    bne  $t1, $zero, vc_invalid

    # ------------------------------------------------
    # 6. Convert starting square to coordinates
    # ------------------------------------------------

    move $a0, $s0
    jal  square_to_coord

    move $s4, $v0       # Starting row
    move $s5, $v1       # Starting column

    # ------------------------------------------------
    # 7. Convert destination square to coordinates
    # ------------------------------------------------

    move $a0, $s1
    jal  square_to_coord

    move $s6, $v0       # Destination row
    move $s7, $v1       # Destination column

    # ------------------------------------------------
    # 8. Calculate movement differences
    # ------------------------------------------------

    subu $t0, $s6, $s4  # Delta row
    subu $t1, $s7, $s5  # Delta column

    # ------------------------------------------------
    # 9. Check two-square diagonal movement
    #
    # Delta row must be +2 or -2
    # Delta col must be +2 or -2
    # ------------------------------------------------

    li   $t2, 2
    beq  $t0, $t2, vc_row_valid

    li   $t2, -2
    bne  $t0, $t2, vc_invalid


vc_row_valid:

    li   $t2, 2
    beq  $t1, $t2, vc_col_valid

    li   $t2, -2
    bne  $t1, $t2, vc_invalid


vc_col_valid:

    # ------------------------------------------------
    # 10. Check pawn movement direction
    # ------------------------------------------------

    # Red pawn = 1
    li   $t2, 1
    beq  $s3, $t2, vc_red_direction

    # Black pawn = 3
    li   $t2, 3
    beq  $s3, $t2, vc_black_direction

    # Kings (2 and 4) can capture both directions
    j vc_check_middle


vc_red_direction:

    # Red captures downwards: delta row = +2
    li   $t2, 2
    bne  $t0, $t2, vc_invalid

    j vc_check_middle


vc_black_direction:

    # Black captures upwards: delta row = -2
    li   $t2, -2
    bne  $t0, $t2, vc_invalid


    # ------------------------------------------------
    # 11. Calculate middle coordinate
    # ------------------------------------------------

vc_check_middle:

    # middle row = (start row + destination row) / 2
    addu $a0, $s4, $s6
    srl  $a0, $a0, 1

    # middle column = (start col + destination col) / 2
    addu $a1, $s5, $s7
    srl  $a1, $a1, 1

    # ------------------------------------------------
    # 12. Convert middle coordinate to square number
    # ------------------------------------------------

    jal coord_to_square

    # Invalid middle coordinate
    bltz $v0, vc_invalid

    # ------------------------------------------------
    # 13. Load the piece in the middle square
    # ------------------------------------------------

    addiu $t0, $v0, -1

    la   $t1, board
    addu $t1, $t1, $t0

    lbu  $t2, 0($t1)    # Middle piece

    # Middle square cannot be empty
    beq  $t2, $zero, vc_invalid

    # ------------------------------------------------
    # 14. Verify that the middle piece is an opponent
    # ------------------------------------------------

    li   $t0, 1
    beq  $s2, $t0, vc_red_captures_black

    # Black captures Red (piece 1 or 2)

    li   $t0, 1
    beq  $t2, $t0, vc_valid

    li   $t0, 2
    beq  $t2, $t0, vc_valid

    j vc_invalid


vc_red_captures_black:

    # Red captures Black (piece 3 or 4)

    li   $t0, 3
    beq  $t2, $t0, vc_valid

    li   $t0, 4
    beq  $t2, $t0, vc_valid

    j vc_invalid


    # ------------------------------------------------
    # 15. Return result
    # ------------------------------------------------

vc_valid:

    li $v0, 1
    j vc_done


vc_invalid:

    li $v0, 0


vc_done:

    # Restore saved registers
    lw $s0, 0($sp)
    lw $s1, 4($sp)
    lw $s2, 8($sp)
    lw $s3, 12($sp)
    lw $s4, 16($sp)
    lw $s5, 20($sp)
    lw $s6, 24($sp)
    lw $s7, 28($sp)
    lw $ra, 32($sp)

    addiu $sp, $sp, 40

    jr $ra



# ============================================================================
# APPLY CAPTURE
# Owner: Member B
#
# Input:
#   $a0 = starting square (1-32)
#   $a1 = destination square (1-32)
#
# Uses:
#   current_player = 1 (Red) or 3 (Black)
#
# Output:
#   $v0 = 1 if capture successfully executed
#   $v0 = 0 if capture failed
#
# Responsibilities:
#   1. Validate the proposed capture.
#   2. Retrieve the moving piece.
#   3. Calculate the middle square.
#   4. Update the three affected board positions.
# ============================================================================

.globl apply_capture

apply_capture:

    # ------------------------------------------------
    # 1. Save registers and preserve input arguments
    # ------------------------------------------------

    addiu $sp, $sp, -32

    sw $s0, 0($sp)
    sw $s1, 4($sp)
    sw $s2, 8($sp)
    sw $s3, 12($sp)
    sw $s4, 16($sp)
    sw $s5, 20($sp)
    sw $ra, 24($sp)

    move $s0, $a0           # Starting square
    move $s1, $a1           # Destination square

    # ------------------------------------------------
    # 2. Validate capture before modifying board
    # ------------------------------------------------

    la   $t0, current_player
    lw   $a2, 0($t0)        # Get current player

    move $a0, $s0
    move $a1, $s1

    jal validate_capture

    # If validation returns 0, stop immediately
    beq  $v0, $zero, ac_invalid

    # ------------------------------------------------
    # 3. Retrieve the moving piece
    # ------------------------------------------------

    la   $t0, board

    addiu $t1, $s0, -1     # Starting array index
    addu  $t0, $t0, $t1

    lbu  $s2, 0($t0)       # Save moving piece

    # ------------------------------------------------
    # 4. Convert starting square to coordinates
    # ------------------------------------------------

    move $a0, $s0

    jal square_to_coord

    move $s3, $v0          # Starting row
    move $s4, $v1          # Starting column

    # ------------------------------------------------
    # 5. Convert destination to coordinates
    # ------------------------------------------------

    move $a0, $s1

    jal square_to_coord

    # Destination row = $v0
    # Destination col = $v1

    # ------------------------------------------------
    # 6. Calculate middle coordinate
    #
    # middleRow = (startRow + destinationRow) / 2
    # middleCol = (startCol + destinationCol) / 2
    # ------------------------------------------------

    addu $a0, $s3, $v0
    srl  $a0, $a0, 1       # Middle row

    addu $a1, $s4, $v1
    srl  $a1, $a1, 1       # Middle column

    # ------------------------------------------------
    # 7. Convert middle coordinate to square number
    # ------------------------------------------------

    jal coord_to_square

    # Verify conversion result
    slti $t0, $v0, 1
    bne  $t0, $zero, ac_invalid

    slti $t0, $v0, 33
    beq  $t0, $zero, ac_invalid

    # Save middle square
    move $s5, $v0

    # ------------------------------------------------
    # 8. Calculate memory addresses
    # ------------------------------------------------

    la   $t0, board        # Board base address

    # Starting address
    addiu $t1, $s0, -1
    addu  $t2, $t0, $t1

    # Destination address
    addiu $t1, $s1, -1
    addu  $t3, $t0, $t1

    # Middle address
    addiu $t1, $s5, -1
    addu  $t4, $t0, $t1

    # ------------------------------------------------
    # 9. Execute the capture
    # ------------------------------------------------

    sb $zero, 0($t2)       # Clear starting square

    sb $zero, 0($t4)       # Remove captured opponent

    sb $s2, 0($t3)         # Move piece to destination

    # ------------------------------------------------
    # 10. Capture successful
    # ------------------------------------------------

    li $v0, 1
    j ac_done


ac_invalid:

    li $v0, 0


# ----------------------------------------------------
# 11. Restore saved registers and return
# ----------------------------------------------------

ac_done:

    lw $s0, 0($sp)
    lw $s1, 4($sp)
    lw $s2, 8($sp)
    lw $s3, 12($sp)
    lw $s4, 16($sp)
    lw $s5, 20($sp)
    lw $ra, 24($sp)

    addiu $sp, $sp, 32

    jr $ra


# ============================================================================
# CHECK CAPTURE
# Owner: Member B
#
# Input:
#   $a0 = current square
#
# Uses:
#   current_player = 1 (Red) or 3 (Black) (shared variable)
#
# Output:
#   $v0 = 1 if at least one legal capture exists
#   $v0 = 0 if no legal capture exists
#
# Does NOT modify the board.
#
# Uses:
#   square_to_coord
#   coord_to_square
#   validate_capture
# ============================================================================

.globl check_capture

check_capture:

    # ------------------------------------------------
    # 1. Save registers
    # ------------------------------------------------

    addiu $sp, $sp, -40

    sw $s0, 0($sp)
    sw $s1, 4($sp)
    sw $s2, 8($sp)
    sw $s3, 12($sp)
    sw $s4, 16($sp)
    sw $s5, 20($sp)
    sw $s6, 24($sp)
    sw $s7, 28($sp)
    sw $ra, 32($sp)

    move $s0, $a0       # Current square
    # Read current player from shared game state
    la   $t0, current_player
    lw   $s1, 0($t0)

    # ------------------------------------------------
    # 2. Validate input square
    # ------------------------------------------------

    slti $t0, $s0, 1
    bne  $t0, $zero, cc_no_capture

    slti $t0, $s0, 33
    beq  $t0, $zero, cc_no_capture

    # ------------------------------------------------
    # 3. Load the current piece
    # ------------------------------------------------

    la   $t0, board

    addiu $t1, $s0, -1
    addu  $t0, $t0, $t1

    lbu  $s2, 0($t0)

    # ------------------------------------------------
    # 4. Determine player, piece type and directions
    #
    # $s5 = row direction
    # $s7 = number of row directions to check
    #
    # Red pawn:   +2, one direction
    # Black pawn: -2, one direction
    # Kings:      -2 and +2
    # ------------------------------------------------

    li   $t0, 1
    beq  $s1, $t0, cc_check_red

    li   $t0, 3
    beq  $s1, $t0, cc_check_black

    j cc_no_capture


cc_check_red:

    li   $t0, 1
    beq  $s2, $t0, cc_red_pawn

    li   $t0, 2
    beq  $s2, $t0, cc_red_king

    j cc_no_capture


cc_red_pawn:

    li   $s5, 2
    li   $s7, 1

    j cc_convert_position


cc_red_king:

    li   $s5, -2
    li   $s7, 2

    j cc_convert_position


cc_check_black:

    li   $t0, 3
    beq  $s2, $t0, cc_black_pawn

    li   $t0, 4
    beq  $s2, $t0, cc_black_king

    j cc_no_capture


cc_black_pawn:

    li   $s5, -2
    li   $s7, 1

    j cc_convert_position


cc_black_king:

    li   $s5, -2
    li   $s7, 2


    # ------------------------------------------------
    # 5. Convert current square to coordinates
    # ------------------------------------------------

cc_convert_position:

    move $a0, $s0

    jal square_to_coord

    move $s3, $v0       # Current row
    move $s4, $v1       # Current column


    # ------------------------------------------------
    # 6. Begin checking possible capture directions
    # ------------------------------------------------

cc_row_loop:

    # Start with column direction -2 (left)

    li   $s6, -2


cc_col_loop:

    # Candidate row = current row + row direction
    addu $a0, $s3, $s5

    # Candidate column = current column + column direction
    addu $a1, $s4, $s6

    # Convert candidate coordinates to square number

    jal coord_to_square

    # If coordinate is outside the board or inaccessible,
    # coord_to_square returns -1.

    bltz $v0, cc_next_column

    # Save candidate destination square

    move $s2, $v0


    # ------------------------------------------------
    # 7. Ask validate_capture whether this candidate works
    # ------------------------------------------------

    move $a0, $s0
    move $a1, $s2
    move $a2, $s1

    jal validate_capture

    # If any candidate is valid, return 1

    li   $t0, 1
    beq  $v0, $t0, cc_capture_found


    # ------------------------------------------------
    # 8. Check the other column direction
    # ------------------------------------------------

cc_next_column:

    li   $t0, -2
    beq  $s6, $t0, cc_try_right

    # Both column directions have been checked.
    j cc_next_row


cc_try_right:

    li   $s6, 2

    j cc_col_loop


    # ------------------------------------------------
    # 9. Check the other row direction (kings only)
    # ------------------------------------------------

cc_next_row:

    li   $t0, 2

    # If only one row direction was allowed, finish.

    beq  $s7, $t0, cc_try_other_row

    j cc_no_capture


cc_try_other_row:

    # Change from -2 to +2

    li   $s5, 2

    # Prevent another row iteration

    li   $s7, 1

    j cc_row_loop


    # ------------------------------------------------
    # 10. Return results
    # ------------------------------------------------

cc_capture_found:

    li $v0, 1
    j cc_done


cc_no_capture:

    li $v0, 0


cc_done:

    # ------------------------------------------------
    # 11. Restore registers
    # ------------------------------------------------

    lw $s0, 0($sp)
    lw $s1, 4($sp)
    lw $s2, 8($sp)
    lw $s3, 12($sp)
    lw $s4, 16($sp)
    lw $s5, 20($sp)
    lw $s6, 24($sp)
    lw $s7, 28($sp)
    lw $ra, 32($sp)

    addiu $sp, $sp, 40

    jr $ra


# ============================================================================
# CHAIN CAPTURE
# Owner: Member B
#
# Input:
#   $a0 = current square of the capturing piece
#
# Shared variable:
#   current_player = 1 (Red) or 3 (Black)
#
# Output:
#   $v0 = 1 if chain ends normally
#   $v0 = 0 if initial state is invalid
#
# Assumptions:
#   - Initial capture has already been executed.
#   - Initial promotion check has already been performed.
#   - check_capture uses $a0 only.
#   - apply_capture reads current_player.
#
# Behaviour:
#   1. Check whether another capture exists.
#   2. Request a landing square.
#   3. Execute a valid capture.
#   4. Update current square.
#   5. Check promotion immediately.
#   6. Repeat until no capture remains.
# ============================================================================

.globl chain_capture

chain_capture:

    # ------------------------------------------------
    # 1. Save registers
    # ------------------------------------------------

    addiu $sp, $sp, -24

    sw $s0, 0($sp)
    sw $s1, 4($sp)
    sw $s2, 8($sp)
    sw $s3, 12($sp)
    sw $ra, 16($sp)

    move $s0, $a0       # Current square

    # ------------------------------------------------
    # 2. Validate starting square
    # ------------------------------------------------

    slti $t0, $s0, 1
    bne  $t0, $zero, chain_invalid_state

    slti $t0, $s0, 33
    beq  $t0, $zero, chain_invalid_state

    # ------------------------------------------------
    # 3. Read and validate current player
    # ------------------------------------------------

    la   $t0, current_player
    lw   $s1, 0($t0)

    li   $t0, 1
    beq  $s1, $t0, chain_check_next

    li   $t0, 3
    bne  $s1, $t0, chain_invalid_state


    # ------------------------------------------------
    # 4. Check whether another capture exists
    # ------------------------------------------------

chain_check_next:

    move $a0, $s0

    jal check_capture

    # No further capture: finish the chain

    beq $v0, $zero, chain_finished

    # Show updated board so player can see where their piece is before chaining

    jal print_board

    # Show all available landing squares for the chain jump

    li   $v0, 4
    la   $a0, chain_avail_msg
    syscall

    move $a0, $s0
    move $a1, $s1
    jal  print_capture_moves

    li   $a0, 10        # '\n'
    li   $v0, 11
    syscall

    # ------------------------------------------------
    # 5. Ask player for another landing square
    # ------------------------------------------------

chain_request_input:

    li   $v0, 4
    la   $a0, chain_prompt_msg
    syscall

    # Read destination square

    li   $v0, 5
    syscall

    move $s2, $v0       # Save entered destination


    # ------------------------------------------------
    # 6. Execute capture
    #
    # apply_capture performs validation internally.
    # ------------------------------------------------

    move $a0, $s0
    move $a1, $s2

    jal apply_capture

    # If capture failed, request another destination

    beq $v0, $zero, chain_invalid_input

    # Print standard checkers capture feedback (e.g. 14x7)

    move $a0, $s0
    move $a1, $s2
    move $a2, $s1
    jal  print_capture_feedback

    # ------------------------------------------------
    # 7. Update current square
    # ------------------------------------------------

    move $s0, $s2


    # ------------------------------------------------
    # 8. Check promotion immediately
    #
    # This must happen before checking another capture.
    # ------------------------------------------------

    la   $t0, board
    addiu $t1, $s0, -1
    addu $t0, $t0, $t1
    lbu  $s3, 0($t0)    # Piece code before promotion check

    move $a0, $s0
    jal  check_promotion

    la   $t0, board
    addiu $t1, $s0, -1
    addu $t0, $t0, $t1
    lbu  $t2, 0($t0)    # Piece code after promotion check
    beq  $t2, $s3, chain_check_next

    # Piece was promoted mid-chain!
    li   $v0, 4
    la   $a0, chain_promo_pre_msg
    syscall
    move $a0, $s0
    li   $v0, 1
    syscall
    li   $v0, 4
    la   $a0, chain_promo_post_msg
    syscall

    # ------------------------------------------------
    # 9. Check for another capture
    # ------------------------------------------------

    j chain_check_next


    # ------------------------------------------------
    # 10. Invalid landing square
    # ------------------------------------------------

chain_invalid_input:

    li   $v0, 4
    la   $a0, chain_invalid_msg
    syscall

    # The board has not changed.
    # The current piece remains at the same square.

    j chain_request_input


    # ------------------------------------------------
    # 11. Chain completed successfully
    # ------------------------------------------------

chain_finished:

    li   $v0, 4
    la   $a0, chain_finished_msg
    syscall

    li $v0, 1

    j chain_done


    # ------------------------------------------------
    # 12. Invalid initial state
    # ------------------------------------------------

chain_invalid_state:

    li $v0, 0


    # ------------------------------------------------
    # 13. Restore registers and return
    # ------------------------------------------------

chain_done:

    lw $s0, 0($sp)
    lw $s1, 4($sp)
    lw $s2, 8($sp)
    lw $s3, 12($sp)
    lw $ra, 16($sp)

    addiu $sp, $sp, 24

    jr $ra


# ============================================================================
# HAS CAPTURE FROM
# Checks whether the piece at square $a0 belonging to explicit player $a1 has
# at least one legal capture (does NOT depend on global current_player).
# Read-only: does NOT modify board.
#
# Input:  $a0 = square (1..32), $a1 = player (1 = Red, 3 = Black)
# Output: $v0 = 1 if a capture exists from $a0, 0 otherwise
# ============================================================================
.globl has_capture_from
has_capture_from:
    addiu $sp, $sp, -24
    sw   $s0, 0($sp)
    sw   $s1, 4($sp)
    sw   $s2, 8($sp)
    sw   $s3, 12($sp)
    sw   $s4, 16($sp)
    sw   $ra, 20($sp)

    move $s0, $a0               # $s0 = square
    move $s1, $a1               # $s1 = player

    slti $t0, $s0, 1
    bne  $t0, $zero, hcf_none
    slti $t0, $s0, 33
    beq  $t0, $zero, hcf_none

    # Fast ownership check on board[square - 1]
    la   $t0, board
    addiu $t1, $s0, -1
    addu $t0, $t0, $t1
    lbu  $t2, 0($t0)

    li   $t3, 1
    beq  $s1, $t3, hcf_check_red
    li   $t3, 3
    beq  $s1, $t3, hcf_check_black
    j    hcf_none

hcf_check_red:
    li   $t3, 1
    beq  $t2, $t3, hcf_owned
    li   $t3, 2
    beq  $t2, $t3, hcf_owned
    j    hcf_none

hcf_check_black:
    li   $t3, 3
    beq  $t2, $t3, hcf_owned
    li   $t3, 4
    beq  $t2, $t3, hcf_owned
    j    hcf_none

hcf_owned:
    move $a0, $s0
    jal  square_to_coord
    move $s2, $v0               # $s2 = row
    move $s3, $v1               # $s3 = col

    li   $s4, 0                 # direction index (0..3)

hcf_loop:
    slti $t0, $s4, 4
    beq  $t0, $zero, hcf_none

    sll  $t1, $s4, 2
    la   $t2, cap_dr
    addu $t2, $t2, $t1
    lw   $t3, 0($t2)
    la   $t2, cap_dc
    addu $t2, $t2, $t1
    lw   $t4, 0($t2)

    addu $a0, $s2, $t3
    addu $a1, $s3, $t4
    jal  coord_to_square
    bltz $v0, hcf_next

    move $a0, $s0
    move $a1, $v0
    move $a2, $s1
    jal  validate_capture
    bne  $v0, $zero, hcf_found

hcf_next:
    addiu $s4, $s4, 1
    j    hcf_loop

hcf_found:
    li   $v0, 1
    j    hcf_done

hcf_none:
    li   $v0, 0

hcf_done:
    lw   $s0, 0($sp)
    lw   $s1, 4($sp)
    lw   $s2, 8($sp)
    lw   $s3, 12($sp)
    lw   $s4, 16($sp)
    lw   $ra, 20($sp)
    addiu $sp, $sp, 24
    jr   $ra


# ============================================================================
# HAS ANY CAPTURE
# Scans all 32 playable squares to determine whether player $a0 has at least
# one legal capture anywhere on the board (for mandatory capture & trap checks).
#
# Input:  $a0 = player (1 = Red, 3 = Black)
# Output: $v0 = 1 if any piece of $a0 can capture, 0 otherwise
# ============================================================================
.globl has_any_capture
has_any_capture:
    addiu $sp, $sp, -16
    sw   $s0, 0($sp)
    sw   $s1, 4($sp)
    sw   $ra, 8($sp)

    move $s0, $a0               # $s0 = player
    li   $s1, 1                 # $s1 = square (1..32)

hac_loop:
    slti $t0, $s1, 33
    beq  $t0, $zero, hac_none

    move $a0, $s1
    move $a1, $s0
    jal  has_capture_from
    bne  $v0, $zero, hac_found

    addiu $s1, $s1, 1
    j    hac_loop

hac_found:
    li   $v0, 1
    j    hac_done

hac_none:
    li   $v0, 0

hac_done:
    lw   $s0, 0($sp)
    lw   $s1, 4($sp)
    lw   $ra, 8($sp)
    addiu $sp, $sp, 16
    jr   $ra


# ============================================================================
# PRINT CAPTURE MOVES
# Prints all legal capture landing squares from square $a0 for player $a1
# (space-separated, ascending order). Read-only.
#
# Input:  $a0 = square (1..32), $a1 = player (1 = Red, 3 = Black)
# Output: $v0 = count of capture destinations printed
# ============================================================================
.globl print_capture_moves
print_capture_moves:
    addiu $sp, $sp, -32
    sw   $s0, 0($sp)
    sw   $s1, 4($sp)
    sw   $s2, 8($sp)
    sw   $s3, 12($sp)
    sw   $s4, 16($sp)
    sw   $s5, 20($sp)
    sw   $s6, 24($sp)
    sw   $ra, 28($sp)

    move $s0, $a0               # $s0 = square
    move $s1, $a1               # $s1 = player
    li   $s5, 0                 # $s5 = count printed

    move $a0, $s0
    jal  square_to_coord
    bltz $v0, pcm_done
    move $s2, $v0               # $s2 = row
    move $s3, $v1               # $s3 = col

    li   $s4, 0                 # direction index (0..3)

pcm_loop:
    slti $t0, $s4, 4
    beq  $t0, $zero, pcm_done

    sll  $t1, $s4, 2
    la   $t2, cap_dr
    addu $t2, $t2, $t1
    lw   $t3, 0($t2)
    la   $t2, cap_dc
    addu $t2, $t2, $t1
    lw   $t4, 0($t2)

    addu $a0, $s2, $t3
    addu $a1, $s3, $t4
    jal  coord_to_square
    bltz $v0, pcm_next

    move $s6, $v0               # candidate landing square
    move $a0, $s0
    move $a1, $s6
    move $a2, $s1
    jal  validate_capture
    beq  $v0, $zero, pcm_next

    beq  $s5, $zero, pcm_print_num
    li   $a0, 32                # ' '
    li   $v0, 11
    syscall

pcm_print_num:
    move $a0, $s6
    li   $v0, 1
    syscall
    addiu $s5, $s5, 1

pcm_next:
    addiu $s4, $s4, 1
    j    pcm_loop

pcm_done:
    move $v0, $s5
    lw   $s0, 0($sp)
    lw   $s1, 4($sp)
    lw   $s2, 8($sp)
    lw   $s3, 12($sp)
    lw   $s4, 16($sp)
    lw   $s5, 20($sp)
    lw   $s6, 24($sp)
    lw   $ra, 28($sp)
    addiu $sp, $sp, 32
    jr   $ra


# ============================================================================
# PRINT MANDATORY CAPTURE PIECES
# Prints all starting squares (1..32) of player $a0 that have a legal capture.
#
# Input:  $a0 = player (1 = Red, 3 = Black)
# Output: $v0 = count of pieces that can capture
# ============================================================================
.globl print_mandatory_capture_pieces
print_mandatory_capture_pieces:
    addiu $sp, $sp, -16
    sw   $s0, 0($sp)
    sw   $s1, 4($sp)
    sw   $s2, 8($sp)
    sw   $ra, 12($sp)

    move $s0, $a0               # $s0 = player
    li   $s1, 1                 # $s1 = square (1..32)
    li   $s2, 0                 # $s2 = count printed

pmp_loop:
    slti $t0, $s1, 33
    beq  $t0, $zero, pmp_done

    move $a0, $s1
    move $a1, $s0
    jal  has_capture_from
    beq  $v0, $zero, pmp_next

    beq  $s2, $zero, pmp_print_sq
    li   $a0, 32                # ' '
    li   $v0, 11
    syscall

pmp_print_sq:
    move $a0, $s1
    li   $v0, 1
    syscall
    addiu $s2, $s2, 1

pmp_next:
    addiu $s1, $s1, 1
    j    pmp_loop

pmp_done:
    move $v0, $s2
    lw   $s0, 0($sp)
    lw   $s1, 4($sp)
    lw   $s2, 8($sp)
    lw   $ra, 12($sp)
    addiu $sp, $sp, 16
    jr   $ra


# ============================================================================
# PRINT CAPTURE FEEDBACK
# Prints standard checkers capture notation:
#   "Captured Red's piece! (21x14)\n"  or  "Captured Black's piece! (14x23)\n"
#
# Input: $a0 = start square, $a1 = dest square, $a2 = capturing player (1 or 3)
# ============================================================================
.globl print_capture_feedback
print_capture_feedback:
    move $t0, $a0               # $t0 = start
    move $t1, $a1               # $t1 = dest

    li   $t2, 3
    beq  $a2, $t2, pcf_cap_red

    la   $a0, cap_fb_black_msg  # Red captured Black's piece
    j    pcf_print_pre

pcf_cap_red:
    la   $a0, cap_fb_red_msg    # Black captured Red's piece

pcf_print_pre:
    li   $v0, 4
    syscall

    move $a0, $t0               # start square
    li   $v0, 1
    syscall

    li   $a0, 120               # 'x'
    li   $v0, 11
    syscall

    move $a0, $t1               # destination square
    li   $v0, 1
    syscall

    la   $a0, cap_fb_close_msg  # ")\n"
    li   $v0, 4
    syscall
    jr   $ra
