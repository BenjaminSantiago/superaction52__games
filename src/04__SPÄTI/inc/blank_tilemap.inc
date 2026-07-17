; A transparent, high-priority space tile. One row is 32 tiles wide.
.MACRO BLANK_ROW
    .dw $2454, $2454, $2454, $2454, $2454, $2454, $2454, $2454
    .dw $2454, $2454, $2454, $2454, $2454, $2454, $2454, $2454
    .dw $2454, $2454, $2454, $2454, $2454, $2454, $2454, $2454
    .dw $2454, $2454, $2454, $2454, $2454, $2454, $2454, $2454
.ENDM

blank_tilemap:
@begin:
    BLANK_ROW
    BLANK_ROW
    BLANK_ROW
    BLANK_ROW
    BLANK_ROW
    BLANK_ROW
    BLANK_ROW
    BLANK_ROW
    BLANK_ROW
    BLANK_ROW
    BLANK_ROW
    BLANK_ROW
    BLANK_ROW
    BLANK_ROW
    BLANK_ROW
    BLANK_ROW
    BLANK_ROW
    BLANK_ROW
    BLANK_ROW
    BLANK_ROW
    BLANK_ROW
    BLANK_ROW
    BLANK_ROW
    BLANK_ROW
    BLANK_ROW
    BLANK_ROW
    BLANK_ROW
    BLANK_ROW
    BLANK_ROW
    BLANK_ROW
    BLANK_ROW
    BLANK_ROW
@end: