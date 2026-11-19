# ============================================================================
# SQUARE NUMBER <-> ROW/COLUMN CONVERSION
# Owner: Member A
# Coordinates: row 0 is the top; column 0 is the left; playable if (row+col)%2=1.
# ============================================================================

.text
.globl square_to_coord
square_to_coord:
    # TODO (Member A): input $a0=square; output $v0=row, $v1=column.
    li $v0, -1
    li $v1, -1
    jr $ra

.globl coord_to_square
coord_to_square:
    # TODO (Member A): input $a0=row, $a1=column; output $v0=square or -1.
    li $v0, -1
    jr $ra
