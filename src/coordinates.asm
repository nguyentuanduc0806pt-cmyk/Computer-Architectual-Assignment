

.text

.globl square_to_coord
square_to_coord:
    # Validate square is in 1..32
    slti $t0, $a0, 1
    bne  $t0, $zero, s2c_invalid
    slti $t0, $a0, 33
    beq  $t0, $zero, s2c_invalid

    addi $t0, $a0, -1           # idx = square - 1 (0..31)
    srl  $v0, $t0, 2            # row = idx / 4 (0..7)
    andi $t1, $t0, 3            # rem = idx % 4 (0..3)
    andi $t2, $v0, 1            # row_parity = row % 2 (0 or 1)

    sll  $t1, $t1, 1            # 2 * rem
    addi $t1, $t1, 1            # 2 * rem + 1
    subu $v1, $t1, $t2          # col = 2 * rem + 1 - (row % 2)
    jr   $ra

s2c_invalid:
    li   $v0, -1
    li   $v1, -1
    jr   $ra


.globl coord_to_square
coord_to_square:
    # Validate row in 0..7
    bltz $a0, c2s_invalid
    slti $t0, $a0, 8
    beq  $t0, $zero, c2s_invalid

    # Validate col in 0..7
    bltz $a1, c2s_invalid
    slti $t0, $a1, 8
    beq  $t0, $zero, c2s_invalid

    # Validate playable dark square: (row + col) % 2 == 1
    addu $t0, $a0, $a1
    andi $t0, $t0, 1
    beq  $t0, $zero, c2s_invalid

    sll  $t0, $a0, 2            # 4 * row
    srl  $t1, $a1, 1            # col / 2
    addu $v0, $t0, $t1          # 4 * row + (col / 2)
    addi $v0, $v0, 1            # + 1 for 1-based square number
    jr   $ra

c2s_invalid:
    li   $v0, -1
    jr   $ra
