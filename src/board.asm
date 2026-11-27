.data
.align 2
.globl board
board: .space 32

.globl current_player
current_player: .word 3       # Black starts first (assignment requirement)

.globl start_square
start_square: .word 0

.globl destination
destination: .word 0

.globl game_over
game_over: .word 0

.globl player1_color
player1_color: .word 3          # 3 = Player 1 is Black (default), 1 = Red

.globl mandatory_capture
mandatory_capture: .word 1      # 1 = Official English rules (mandatory capture), 0 = Casual

# Display strings for enhanced checkerboard visualization
brd_header:     .asciiz "\n           GAME BOARD                       SQUARE NUMBERS (1-32)\n"
brd_border:     .asciiz "   +---+---+---+---+---+---+---+---+    +---+---+---+---+---+---+---+---+\n"
brd_gap:        .asciiz "    |"
brd_light_cell: .asciiz " . |"
brd_map_empty:  .asciiz "   |"
brd_footer:     .asciiz "     0   1   2   3   4   5   6   7      b/B=Black  r/R=Red  0=Empty .=Light\n"
brd_count_pre:  .asciiz "   Pieces remaining -> Black: "
brd_count_mid:  .asciiz " | Red: "

.text

.globl init_board
init_board:
    la   $t0, board             # $t0 = base address of board
    li   $t1, 0                 # $t1 = loop index i (0..31)

init_board_loop:
    slti $t2, $t1, 32           # Continue while i < 32
    beq  $t2, $zero, init_board_done

    slti $t2, $t1, 12           # Is i < 12? (squares 1..12)
    bne  $t2, $zero, init_set_red

    slti $t2, $t1, 20           # Is i < 20? (squares 13..20)
    bne  $t2, $zero, init_set_empty

    li   $t2, 3                 # Otherwise i in 20..31 -> Black pawn (3)
    j    init_store_byte

init_set_red:
    li   $t2, 1                 # Red pawn (1)
    j    init_store_byte

init_set_empty:
    li   $t2, 0                 # Empty playable square (0)

init_store_byte:
    addu $t3, $t0, $t1          # $t3 = &board[i]
    sb   $t2, 0($t3)            # Store 1-byte piece code
    addi $t1, $t1, 1            # i++
    j    init_board_loop

init_board_done:
    jr   $ra



.globl print_board
print_board:
    addi $sp, $sp, -24          # Allocate stack frame for $ra and $s0-$s4
    sw   $ra, 20($sp)
    sw   $s4, 16($sp)
    sw   $s3, 12($sp)
    sw   $s2, 8($sp)
    sw   $s1, 4($sp)
    sw   $s0, 0($sp)

    la   $s2, board             # $s2 = base address of board
    li   $s3, 0                 # $s3 = Red piece count
    li   $s4, 0                 # $s4 = Black piece count

    # Print board titles and top horizontal border
    li   $v0, 4
    la   $a0, brd_header
    syscall
    li   $v0, 4
    la   $a0, brd_border
    syscall

    li   $s0, 0                 # $s0 = row (0..7)

print_row_loop:
    slti $t0, $s0, 8            # While row < 8
    beq  $t0, $zero, print_board_footer

    # Row label prefix: " <row> |"
    li   $a0, 32                # ' '
    li   $v0, 11
    syscall
    move $a0, $s0               # row digit (0..7)
    li   $v0, 1
    syscall
    li   $a0, 32                # ' '
    li   $v0, 11
    syscall
    li   $a0, 124               # '|'
    li   $v0, 11
    syscall

    # --- Left half: 8 cells of the live game board ---
    li   $s1, 0                 # $s1 = col (0..7)

print_col_loop:
    slti $t0, $s1, 8            # While col < 8
    beq  $t0, $zero, print_map_start

    # Check if square (row, col) is playable: (row + col) & 1 == 1
    addu $t0, $s0, $s1          # $t0 = row + col
    andi $t0, $t0, 1            # $t0 = (row + col) % 2
    beq  $t0, $zero, print_inaccessible

    # Playable square: convert (row, col) to square number 1..32
    move $a0, $s0
    move $a1, $s1
    jal  coord_to_square        # $v0 = square (1..32) or -1 if invalid

    # Guard against invalid square index (< 1 or > 32)
    slti $t0, $v0, 1
    bne  $t0, $zero, print_unknown
    slti $t0, $v0, 33
    beq  $t0, $zero, print_unknown

    addi $t1, $v0, -1           # array index = square - 1
    addu $t1, $s2, $t1          # $t1 = &board[square - 1]
    lb   $t2, 0($t1)            # $t2 = piece code

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
    li   $t4, 63                # '?' fallback for unexpected code
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
    addi $s3, $s3, 1            # red_count++
    li   $t4, 114               # 'r'
    j    print_piece_cell

map_red_king:
    addi $s3, $s3, 1            # red_count++
    li   $t4, 82                # 'R'
    j    print_piece_cell

map_black_pawn:
    addi $s4, $s4, 1            # black_count++
    li   $t4, 98                # 'b'
    j    print_piece_cell

map_black_king:
    addi $s4, $s4, 1            # black_count++
    li   $t4, 66                # 'B'

print_piece_cell:
    # Print " <char> |"
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
    addi $s1, $s1, 1            # col++
    j    print_col_loop

    # --- Right half: 8 cells of the 1..32 square number reference map ---
print_map_start:
    li   $v0, 4
    la   $a0, brd_gap           # "    |"
    syscall

    li   $s1, 0                 # $s1 = col (0..7)

print_map_loop:
    slti $t0, $s1, 8
    beq  $t0, $zero, print_row_end

    addu $t0, $s0, $s1
    andi $t0, $t0, 1
    beq  $t0, $zero, print_map_light

    move $a0, $s0
    move $a1, $s1
    jal  coord_to_square        # $v0 = square (1..32)
    move $t2, $v0

    # Format as " <n> |" for 1..9 or "<nn> |" for 10..32 (3 chars inside cell)
    slti $t0, $t2, 10
    beq  $t0, $zero, print_map_two_digit

    li   $a0, 32                # leading space for 1-digit numbers
    li   $v0, 11
    syscall

print_map_two_digit:
    move $a0, $t2               # print square number
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
    addi $s1, $s1, 1            # col++
    j    print_map_loop

print_row_end:
    li   $a0, 10                # '\n'
    li   $v0, 11
    syscall
    li   $v0, 4
    la   $a0, brd_border        # horizontal grid separator
    syscall
    addi $s0, $s0, 1            # row++
    j    print_row_loop

print_board_footer:
    # Column numbers, legend, and live remaining piece counts
    li   $v0, 4
    la   $a0, brd_footer
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
    lw   $s0, 0($sp)            # Restore saved registers and stack frame
    lw   $s1, 4($sp)
    lw   $s2, 8($sp)
    lw   $s3, 12($sp)
    lw   $s4, 16($sp)
    lw   $ra, 20($sp)
    addi $sp, $sp, 24
    jr   $ra
