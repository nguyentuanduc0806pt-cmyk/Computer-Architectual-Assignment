# ============================================================================
# GAME CONTROL HELPERS
# Owner: Member B
# main.asm owns the entry point and overall game loop.
# ============================================================================

.text
.globl check_winner
check_winner:
    # TODO (Member B): $a0=player to check.
    # Minimum requirement: detect when that player's opponent has no pieces.
    # Agree on and document the return-value contract before implementation.
    jr $ra
