# ============================================================================
# BOARD STORAGE, INITIALIZATION, AND DISPLAY
# Owner: Member A
# Piece codes: 0=empty, 1=Red pawn, 2=Red king, 3=Black pawn, 4=Black king
# Squares 1..32 map to board[0..31]. Each element is one byte.
# ============================================================================

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
    # TODO (Member A): initialize 12 Red pawns, 12 Black pawns, and 8 empty squares.
    jr $ra

.globl print_board
print_board:
    # TODO (Member A): print the full 8x8 view; inaccessible squares are not stored.
    jr $ra
