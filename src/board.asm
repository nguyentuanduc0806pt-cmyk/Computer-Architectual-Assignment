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
    addi $sp, $sp, -16          # Allocate stack frame for $ra and $s0-$s2
    sw   $ra, 12($sp)
    sw   $s2, 8($sp)
    sw   $s1, 4($sp)
    sw   $s0, 0($sp)

    la   $s2, board             # $s2 = base address of board
    li   $s0, 0                 # $s0 = row (0..7)

print_row_loop:
    slti $t0, $s0, 8            # While row < 8
    beq  $t0, $zero, print_board_done
    li   $s1, 0                 # $s1 = col (0..7)

print_col_loop:
    slti $t0, $s1, 8            # While col < 8
    beq  $t0, $zero, print_row_end

    # Check if square (row, col) is playable: (row + col) & 1 == 1
    addu $t0, $s0, $s1          # $t0 = row + col
    andi $t0, $t0, 1            # $t0 = (row + col) % 2
    beq  $t0, $zero, print_inaccessible

    # Playable square: convert (row, col) to square number 1..32
    move $a0, $s0
    move $a1, $s1
    jal  coord_to_square        # $v0 = square (1..32) or -1 if unimplemented

    # Guard against invalid square index (< 1 or > 32)
    slti $t0, $v0, 1
    bne  $t0, $zero, print_unknown
    slti $t0, $v0, 33
    beq  $t0, $zero, print_unknown

    addi $t1, $v0, -1           # array index = square - 1
    addu $t1, $s2, $t1          # $t1 = &board[square - 1]
    lb   $t2, 0($t1)            # $t2 = piece code

    # Map piece code to display character
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
    li   $a0, 63                # '?' fallback for unexpected code
    j    print_char

print_inaccessible:
    li   $a0, 45                # '-' for non-playable light squares (assignment's illustrated output uses -)
    j    print_char

map_empty:
    li   $a0, 48                # '0'
    j    print_char

map_red_pawn:
    li   $a0, 114               # 'r'
    j    print_char

map_red_king:
    li   $a0, 82                # 'R'
    j    print_char

map_black_pawn:
    li   $a0, 98                # 'b'
    j    print_char

map_black_king:
    li   $a0, 66                # 'B'

print_char:
    li   $v0, 11                # Syscall 11: print_character
    syscall

    # Print space separator between columns (except after column 7)
    slti $t0, $s1, 7
    beq  $t0, $zero, print_col_next
    li   $a0, 32                # ' '
    li   $v0, 11
    syscall

print_col_next:
    addi $s1, $s1, 1            # col++
    j    print_col_loop

print_row_end:
    li   $a0, 10                # '\n'
    li   $v0, 11
    syscall
    addi $s0, $s0, 1            # row++
    j    print_row_loop

print_board_done:
    lw   $s0, 0($sp)            # Restore saved registers and stack frame
    lw   $s1, 4($sp)
    lw   $s2, 8($sp)
    lw   $ra, 12($sp)
    addi $sp, $sp, 16
    jr   $ra
