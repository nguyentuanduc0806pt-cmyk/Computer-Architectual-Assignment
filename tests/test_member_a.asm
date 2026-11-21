# ==============================================================================
# File: tests/test_member_a.asm
# Phu trach: Thanh vien A
# Mo ta: Chuong trinh kiem thu doc lap cho cac module cua Thanh vien A.
#        Chua du lieu dung chung (.data) va cac ca kiem thu (Cot moc 1 -> 4).
# Cach chay tren MARS:
#   Mo file nay trong MARS va Assemble & Run.
#   (Luu y: Cac duong dan .include ben duoi tinh theo thu muc 'tests/').
# ==============================================================================

.data
# Because board.asm already owns these shared variables.
# --- Chuoi phuc vu in ket qua test ---
msg_init:       .asciiz "=== TEST 1: Khoi tao va in ban co ===\n"
msg_coord_ok:   .asciiz "\n=== TEST 2: Chuyen doi toa do (1..32) -> PASS ===\n"
msg_coord_fail: .asciiz "\n=== TEST 2: Chuyen doi toa do -> FAIL tai o: "
msg_move_test:  .asciiz "\n=== TEST 3: Thu nuoc di 21 -> 17 (Den) ===\n"
msg_valid:      .asciiz "Ket qua validate_normal_move: HOP LE (1)\n"
msg_invalid:    .asciiz "Ket qua validate_normal_move: KHONG HOP LE (0)\n"
newline:        .asciiz "\n"

.text
.globl main

main:
    # ------------------------------------------------------------------
    # TEST 1 (Cot moc 1 & 2): Khoi tao va in ban co ban dau
    # ------------------------------------------------------------------
    li   $v0, 4
    la   $a0, msg_init
    syscall

    jal  init_board
    jal  print_board

    # ------------------------------------------------------------------
    # TEST 2 (Cot moc 2): Kiem tra square_to_coord <-> coord_to_square
    #                     cho tat ca 32 o (1..32)
    # ------------------------------------------------------------------
    li   $s0, 1                 # $s0 = square (1..32)
    li   $s1, 32

test_coord_loop:
    bgt  $s0, $s1, test_coord_pass

    move $a0, $s0
    jal  square_to_coord        # $v0 = row, $v1 = col

    move $a0, $v0
    move $a1, $v1
    jal  coord_to_square        # $v0 = square_back

    bne  $v0, $s0, test_coord_err

    addi $s0, $s0, 1
    j    test_coord_loop

test_coord_err:
    li   $v0, 4
    la   $a0, msg_coord_fail
    syscall
    li   $v0, 1
    move $a0, $s0
    syscall
    li   $v0, 4
    la   $a0, newline
    syscall
    j    after_coord_test

test_coord_pass:
    li   $v0, 4
    la   $a0, msg_coord_ok
    syscall

after_coord_test:
    # ------------------------------------------------------------------
    # TEST 3 (Cot moc 3): Thu kiem tra & thuc hien nuoc di 21 -> 17
    # ------------------------------------------------------------------
    li   $v0, 4
    la   $a0, msg_move_test
    syscall

    li   $a0, 21                # start = 21
    li   $a1, 17                # dest = 17
    li   $a2, 3                 # current_player = 3 (Den)
    jal  validate_normal_move

    beqz $v0, print_move_invalid

    li   $v0, 4
    la   $a0, msg_valid
    syscall

    li   $a0, 21
    li   $a1, 17
    jal  apply_normal_move
    jal  print_board
    j    exit_test

print_move_invalid:
    li   $v0, 4
    la   $a0, msg_invalid
    syscall

exit_test:
    li   $v0, 10                # Ket thuc chuong trinh
    syscall


# ==============================================================================
# Nap cac module cua Thanh vien A
# Luu y: Phai dat .include o cuoi file (sau main) de MARS khong nhay vao
#        cac ham con khi bat dau chay tu dau segment .text.
# ==============================================================================
.include "../src/board.asm"
.include "../src/coordinates.asm"
.include "../src/movement.asm"
.include "../src/promotion.asm"
