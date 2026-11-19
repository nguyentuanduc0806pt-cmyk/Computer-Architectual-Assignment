# ============================================================================
# CAPTURE VALIDATION, EXECUTION, AND CHAIN CAPTURES
# Owner: Member B
# A chain capture must continue while another capture is available.
# Promotion during a capture must happen immediately so a new king can capture
# backwards in the same chain.
# ============================================================================

.text
.globl validate_capture
validate_capture:
    # TODO (Member B): $a0=start, $a1=destination, $a2=current player.
    # Return $v0=1 for valid, 0 for invalid. Do not change board memory.
    li $v0, 0
    jr $ra

.globl apply_capture
apply_capture:
    # TODO (Member B): move the piece and remove the jumped-over opponent piece.
    jr $ra

.globl check_capture
check_capture:
    # TODO (Member B): $a0=current square; return $v0=1 if a capture is available.
    li $v0, 0
    jr $ra

.globl chain_capture
chain_capture:
    # TODO (Member B): handle repeated captures by the same piece and player.
    # IMPORTANT: agree on the return-value contract before connecting this routine
    # to the main loop (the work plan does not define one).
    jr $ra
