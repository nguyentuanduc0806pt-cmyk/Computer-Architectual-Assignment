.data
.align 2
.globl board
board: .space 50                # Up to 50 playable squares (32 for 8x8, 50 for 10x10)

.globl captured_mask
captured_mask: .space 50        # 1 = already jumped in current International chain

.align 2
.globl current_player
current_player: .word 3         # Black starts first (3 = Black, 1 = Red)

.globl start_square
start_square: .word 0

.globl destination
destination: .word 0

.globl game_over
game_over: .word 0

.globl player1_color
player1_color: .word 3          # 3 = Player 1 is Black (default), 1 = Red

.globl mandatory_capture
mandatory_capture: .word 1      # 1 = Mandatory capture ON, 0 = Casual (American only)

.globl ruleset
ruleset: .word 0                # 0 = American/English (8x8), 1 = International (10x10)

.globl board_dim
board_dim: .word 8              # 8 for American, 10 for International

.globl num_squares
num_squares: .word 32           # 32 for American, 50 for International

.globl squares_per_row
squares_per_row: .word 4        # 4 for American, 5 for International

.globl in_capture_chain
in_capture_chain: .word 0       # 1 during an active multi-jump turn (deferred removal in Intl)

# Display strings for enhanced checkerboard visualization
brd_hdr_am_blk:  .asciiz "\n      GAME BOARD (Black's View)              SQUARE NUMBERS (1-32)\n"
brd_hdr_am_red:  .asciiz "\n   GAME BOARD (Red's View - Rotated)         SQUARE NUMBERS (1-32)\n"
brd_hdr_in_blk:  .asciiz "\n         GAME BOARD 10x10 (Black's View)                 SQUARE NUMBERS (1-50)\n"
brd_hdr_in_red:  .asciiz "\n      GAME BOARD 10x10 (Red's View - Rotated)            SQUARE NUMBERS (1-50)\n"
brd_border_pre:  .asciiz "   +"
brd_border_seg:  .asciiz "---+"
brd_border_mid:  .asciiz "    +"
brd_gap:         .asciiz "    |"
brd_light_cell:  .asciiz " . |"
brd_map_empty:   .asciiz "   |"
brd_col_pre:     .asciiz "     "
brd_col_sep:     .asciiz "   "
brd_legend:      .asciiz "  b/B=Black  r/R=Red  0=Empty .=Light\n"
brd_count_pre:   .asciiz "   Pieces remaining -> Black: "
brd_count_mid:   .asciiz " | Red: "

.text

# ============================================================================
# INIT BOARD
# Initializes board[0..num_squares-1] based on global `ruleset`:
#   ruleset == 0 (American 8x8):      12 Red (1..12), 8 Empty (13..20), 12 Black (21..32)
#   ruleset == 1 (International 10x10): 20 Red (1..20), 10 Empty (21..30), 20 Black (31..50)
# Also syncs board_dim, num_squares, squares_per_row and clears captured_mask.
# ============================================================================
.globl init_board
init_board:
    # Clear all 50 bytes of board and captured_mask first
    la   $t0, board
    la   $t4, captured_mask
    li   $t1, 0
    li   $t2, 50
init_clear_loop:
    beq  $t1, $t2, init_check_ruleset
    sb   $zero, 0($t0)
    sb   $zero, 0($t4)
    addiu $t0, $t0, 1
    addiu $t4, $t4, 1
    addiu $t1, $t1, 1
    j    init_clear_loop

init_check_ruleset:
    la   $t0, ruleset
    lw   $t1, 0($t0)
    bne  $t1, $zero, init_intl_setup

    # --- American/English Checkers (8x8) ---
    la   $t0, board_dim
    li   $t1, 8
    sw   $t1, 0($t0)
    la   $t0, num_squares
    li   $t1, 32
    sw   $t1, 0($t0)
    la   $t0, squares_per_row
    li   $t1, 4
    sw   $t1, 0($t0)

    li   $t5, 12                # Red ends at index 12 (squares 1..12)
    li   $t6, 20                # Empty ends at index 20 (squares 13..20)
    li   $t7, 32                # Total squares = 32
    j    init_fill_start

init_intl_setup:
    # --- International Checkers (10x10) ---
    la   $t0, board_dim
    li   $t1, 10
    sw   $t1, 0($t0)
    la   $t0, num_squares
    li   $t1, 50
    sw   $t1, 0($t0)
    la   $t0, squares_per_row
    li   $t1, 5
    sw   $t1, 0($t0)

    li   $t5, 20                # Red ends at index 20 (squares 1..20)
    li   $t6, 30                # Empty ends at index 30 (squares 21..30)
    li   $t7, 50                # Total squares = 50

init_fill_start:
    la   $t0, board
    li   $t1, 0                 # i = 0 .. num_squares-1

init_board_loop:
    slt  $t2, $t1, $t7
    beq  $t2, $zero, init_board_done

    slt  $t2, $t1, $t5          # i < red_end -> Red pawn (1)
    bne  $t2, $zero, init_set_red

    slt  $t2, $t1, $t6          # i < empty_end -> Empty (0)
    bne  $t2, $zero, init_set_empty

    li   $t2, 3                 # Otherwise -> Black pawn (3)
    j    init_store_byte

init_set_red:
    li   $t2, 1
    j    init_store_byte

init_set_empty:
    li   $t2, 0

init_store_byte:
    addu $t3, $t0, $t1
    sb   $t2, 0($t3)
    addiu $t1, $t1, 1
    j    init_board_loop

init_board_done:
    jr   $ra


# ============================================================================
# HELPER: PRINT BOARD HORIZONTAL BORDER
# Input: $a0 = board_dim (8 or 10)
# Prints: "   +---+---+...+    +---+---+...+\n"
# ============================================================================
print_board_border:
    move $t5, $a0               # $t5 = dim

    li   $v0, 4
    la   $a0, brd_border_pre
    syscall

    li   $t6, 0
pbb_left:
    beq  $t6, $t5, pbb_mid
    li   $v0, 4
    la   $a0, brd_border_seg
    syscall
    addiu $t6, $t6, 1
    j    pbb_left

pbb_mid:
    li   $v0, 4
    la   $a0, brd_border_mid
    syscall

    li   $t6, 0
pbb_right:
    beq  $t6, $t5, pbb_end
    li   $v0, 4
    la   $a0, brd_border_seg
    syscall
    addiu $t6, $t6, 1
    j    pbb_right

pbb_end:
    li   $a0, 10                # '\n'
    li   $v0, 11
    syscall
    jr   $ra


# ============================================================================
# PRINT BOARD
# Displays the board (8x8 or 10x10) alongside its 1..32 / 1..50 square map.
# Automatically rotates the board 180 degrees when current_player == 1 (Red)
# so the active player always plays from the bottom upward.
# ============================================================================
.globl print_board
print_board:
    addiu $sp, $sp, -36
    sw   $ra, 32($sp)
    sw   $s7, 28($sp)
    sw   $s6, 24($sp)
    sw   $s5, 20($sp)
    sw   $s4, 16($sp)
    sw   $s3, 12($sp)
    sw   $s2, 8($sp)
    sw   $s1, 4($sp)
    sw   $s0, 0($sp)

    la   $s2, board             # $s2 = base address of board
    li   $s3, 0                 # $s3 = Red piece count
    li   $s4, 0                 # $s4 = Black piece count

    # Determine board_dim ($s6) and flipped flag ($s5: 1 if Red's turn, 0 if Black's)
    la   $t0, board_dim
    lw   $s6, 0($t0)            # $s6 = 8 or 10

    la   $t0, current_player
    lw   $t1, 0($t0)
    li   $t2, 1
    beq  $t1, $t2, pb_set_flipped
    li   $s5, 0                 # Black's view (normal 0..dim-1)
    j    pb_print_header
pb_set_flipped:
    li   $s5, 1                 # Red's view (rotated 180 deg: dim-1..0)

pb_print_header:
    li   $t0, 10
    beq  $s6, $t0, pb_hdr_intl
    # 8x8 header
    bne  $s5, $zero, pb_hdr_am_red
    la   $a0, brd_hdr_am_blk
    j    pb_hdr_out
pb_hdr_am_red:
    la   $a0, brd_hdr_am_red
    j    pb_hdr_out
pb_hdr_intl:
    bne  $s5, $zero, pb_hdr_in_red
    la   $a0, brd_hdr_in_blk
    j    pb_hdr_out
pb_hdr_in_red:
    la   $a0, brd_hdr_in_red
pb_hdr_out:
    li   $v0, 4
    syscall

    move $a0, $s6
    jal  print_board_border

    li   $s0, 0                 # $s0 = display row index i (0..dim-1)

print_row_loop:
    slt  $t0, $s0, $s6
    beq  $t0, $zero, print_board_footer

    # Compute actual board row into $s7
    beq  $s5, $zero, pb_row_normal
    addiu $t0, $s6, -1
    subu $s7, $t0, $s0          # row = (dim - 1) - i
    j    pb_row_label
pb_row_normal:
    move $s7, $s0               # row = i

pb_row_label:
    # Row label prefix: " <row> |"
    li   $a0, 32                # ' '
    li   $v0, 11
    syscall
    move $a0, $s7               # actual row digit (0..7 or 0..9)
    li   $v0, 1
    syscall
    li   $a0, 32                # ' '
    li   $v0, 11
    syscall
    li   $a0, 124               # '|'
    li   $v0, 11
    syscall

    # --- Left half: dim cells of the live game board ---
    li   $s1, 0                 # $s1 = display col index j (0..dim-1)

print_col_loop:
    slt  $t0, $s1, $s6
    beq  $t0, $zero, print_map_start

    # Compute actual board col into $t5
    beq  $s5, $zero, pb_col_normal
    addiu $t0, $s6, -1
    subu $t5, $t0, $s1          # col = (dim - 1) - j
    j    pb_col_check
pb_col_normal:
    move $t5, $s1               # col = j

pb_col_check:
    # Check if square (row, col) is playable: (row + col) & 1 == 1
    addu $t0, $s7, $t5
    andi $t0, $t0, 1
    beq  $t0, $zero, print_inaccessible

    # Playable square: convert (row, col) to square number 1..num_squares
    move $a0, $s7
    move $a1, $t5
    jal  coord_to_square        # $v0 = square or -1
    bltz $v0, print_unknown

    addiu $t1, $v0, -1          # array index = square - 1

    # Check if square is marked as already captured mid-chain
    la   $t6, captured_mask
    addu $t6, $t6, $t1
    lbu  $t7, 0($t6)
    bne  $t7, $zero, map_captured_mid

    addu $t1, $s2, $t1          # $t1 = &board[square - 1]
    lbu  $t2, 0($t1)            # $t2 = piece code

    # Map piece code to display character and update piece counts
    beq  $t2, $zero, map_empty
    li   $t3, 1
    beq  $t2, $t3, map_red_pawn
    li   $t3, 2
    beq  $t2, $t3, map_red_king
    li   $t3, 3
    beq  $t2, $t3, map_black_pawn
    li   $t3, 4
    beq  $t2, $t3, map_black_king

print_unknown:
    li   $t4, 63                # '?'
    j    print_piece_cell

map_captured_mid:
    li   $t4, 120               # 'x' (captured piece awaiting end of chain)
    j    print_piece_cell

print_inaccessible:
    li   $v0, 4
    la   $a0, brd_light_cell    # " . |"
    syscall
    j    print_col_next

map_empty:
    li   $t4, 48                # '0'
    j    print_piece_cell

map_red_pawn:
    addiu $s3, $s3, 1
    li   $t4, 114               # 'r'
    j    print_piece_cell

map_red_king:
    addiu $s3, $s3, 1
    li   $t4, 82                # 'R'
    j    print_piece_cell

map_black_pawn:
    addiu $s4, $s4, 1
    li   $t4, 98                # 'b'
    j    print_piece_cell

map_black_king:
    addiu $s4, $s4, 1
    li   $t4, 66                # 'B'

print_piece_cell:
    li   $a0, 32                # ' '
    li   $v0, 11
    syscall
    move $a0, $t4               # piece symbol
    li   $v0, 11
    syscall
    li   $a0, 32                # ' '
    li   $v0, 11
    syscall
    li   $a0, 124               # '|'
    li   $v0, 11
    syscall

print_col_next:
    addiu $s1, $s1, 1
    j    print_col_loop

    # --- Right half: dim cells of the square number reference map ---
print_map_start:
    li   $v0, 4
    la   $a0, brd_gap           # "    |"
    syscall

    li   $s1, 0                 # $s1 = display col index j (0..dim-1)

print_map_loop:
    slt  $t0, $s1, $s6
    beq  $t0, $zero, print_row_end

    beq  $s5, $zero, pb_mcol_normal
    addiu $t0, $s6, -1
    subu $t5, $t0, $s1          # col = (dim - 1) - j
    j    pb_mcol_check
pb_mcol_normal:
    move $t5, $s1

pb_mcol_check:
    addu $t0, $s7, $t5
    andi $t0, $t0, 1
    beq  $t0, $zero, print_map_light

    move $a0, $s7
    move $a1, $t5
    jal  coord_to_square        # $v0 = square (1..32 or 1..50)
    move $t2, $v0

    # Format as " <n> |" for 1..9 or "<nn> |" for 10..50
    slti $t0, $t2, 10
    beq  $t0, $zero, print_map_two_digit

    li   $a0, 32                # leading space for 1-digit numbers
    li   $v0, 11
    syscall

print_map_two_digit:
    move $a0, $t2
    li   $v0, 1
    syscall
    li   $a0, 32                # trailing space
    li   $v0, 11
    syscall
    li   $a0, 124               # '|'
    li   $v0, 11
    syscall
    j    print_map_next

print_map_light:
    li   $v0, 4
    la   $a0, brd_map_empty     # "   |"
    syscall

print_map_next:
    addiu $s1, $s1, 1
    j    print_map_loop

print_row_end:
    li   $a0, 10                # '\n'
    li   $v0, 11
    syscall
    move $a0, $s6
    jal  print_board_border
    addiu $s0, $s0, 1
    j    print_row_loop

print_board_footer:
    # Print column labels matching current orientation
    li   $v0, 4
    la   $a0, brd_col_pre
    syscall

    li   $s1, 0
pb_col_lbl_loop:
    slt  $t0, $s1, $s6
    beq  $t0, $zero, pb_col_lbl_done

    beq  $s5, $zero, pb_clbl_normal
    addiu $t0, $s6, -1
    subu $a0, $t0, $s1
    j    pb_clbl_print
pb_clbl_normal:
    move $a0, $s1
pb_clbl_print:
    li   $v0, 1
    syscall
    li   $v0, 4
    la   $a0, brd_col_sep
    syscall
    addiu $s1, $s1, 1
    j    pb_col_lbl_loop

pb_col_lbl_done:
    li   $v0, 4
    la   $a0, brd_legend
    syscall

    li   $v0, 4
    la   $a0, brd_count_pre
    syscall
    move $a0, $s4               # Black count
    li   $v0, 1
    syscall
    li   $v0, 4
    la   $a0, brd_count_mid
    syscall
    move $a0, $s3               # Red count
    li   $v0, 1
    syscall
    li   $a0, 10                # '\n'
    li   $v0, 11
    syscall

print_board_done:
    lw   $s0, 0($sp)
    lw   $s1, 4($sp)
    lw   $s2, 8($sp)
    lw   $s3, 12($sp)
    lw   $s4, 16($sp)
    lw   $s5, 20($sp)
    lw   $s6, 24($sp)
    lw   $s7, 28($sp)
    lw   $ra, 32($sp)
    addiu $sp, $sp, 36
    jr   $ra
