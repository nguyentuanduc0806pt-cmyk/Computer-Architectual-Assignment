# ============================================================================
# CO2008 CHECKERS — PROGRAM ENTRY POINT
# Owner: Member B
# TODO: Implement the main game loop, user input, turn progression, and exit.
# MARS 4.5: Open this file and assemble all files in this directory.
# ============================================================================

.data
startup_message: .asciiz "CO2008 CHECKERS\nProject setup successful. Multi-file MARS assembly is working.\n"

.text
.globl main
main:
    # Temporary test for Member A's board + coordinates modules.
    # Replace with the actual game loop later (Member B).
    li   $v0, 4
    la   $a0, startup_message
    syscall

    jal  init_board
    jal  print_board

    li   $v0, 10
    syscall
