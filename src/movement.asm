# ============================================================================
# NORMAL MOVE VALIDATION AND EXECUTION
# Owner: Member A
# Validation must not modify board memory. Execution performs the board update.
# ============================================================================

.text
.globl validate_normal_move
validate_normal_move:
    # TODO (Member A): $a0=start, $a1=destination, $a2=current player.
    # Return $v0=1 for valid, 0 for invalid. Do not change the board here.
    li $v0, 0
    jr $ra

.globl apply_normal_move
apply_normal_move:
    # TODO (Member A): $a0=start, $a1=destination. Move piece and clear start.
    jr $ra
