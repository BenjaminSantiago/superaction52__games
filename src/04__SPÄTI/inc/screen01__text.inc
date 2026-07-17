; 32x32 BG tilemap for screen 01's text layer.
; The message is inset by two 8x8 tiles on every side of the visible area.
; $2454 is the transparent, high-priority space tile.
.MACRO SCREEN01_TEXT_BLANK_ROW
    .dw $2454, $2454, $2454, $2454, $2454, $2454, $2454, $2454
    .dw $2454, $2454, $2454, $2454, $2454, $2454, $2454, $2454
    .dw $2454, $2454, $2454, $2454, $2454, $2454, $2454, $2454
    .dw $2454, $2454, $2454, $2454, $2454, $2454, $2454, $2454
.ENDM

screen01_text_map:
@begin:
    ; Two-row top inset.
    SCREEN01_TEXT_BLANK_ROW ; 00
    SCREEN01_TEXT_BLANK_ROW ; 01
    SCREEN01_TEXT_BLANK_ROW ; 02
    SCREEN01_TEXT_BLANK_ROW ; 03
    SCREEN01_TEXT_BLANK_ROW ; 04
    SCREEN01_TEXT_BLANK_ROW ; 05
    SCREEN01_TEXT_BLANK_ROW ; 06
    SCREEN01_TEXT_BLANK_ROW ; 07
    SCREEN01_TEXT_BLANK_ROW ; 08
    SCREEN01_TEXT_BLANK_ROW ; 09
    SCREEN01_TEXT_BLANK_ROW ; 10
    SCREEN01_TEXT_BLANK_ROW ; 11
    SCREEN01_TEXT_BLANK_ROW ; 12
    SCREEN01_TEXT_BLANK_ROW ; 13
    SCREEN01_TEXT_BLANK_ROW ; 14
    SCREEN01_TEXT_BLANK_ROW ; 15
    SCREEN01_TEXT_BLANK_ROW ; 16
    SCREEN01_TEXT_BLANK_ROW ; 17
    SCREEN01_TEXT_BLANK_ROW ; 18
    SCREEN01_TEXT_BLANK_ROW ; 19
    SCREEN01_TEXT_BLANK_ROW ; 20
    SCREEN01_TEXT_BLANK_ROW ; 21
    SCREEN01_TEXT_BLANK_ROW ; 22
    SCREEN01_TEXT_BLANK_ROW ; 23
@message_begin:
    ; Row 24: "I used to take walks,"
    .dw $2454, $2454
    .dw $2408, $2454, $242E, $242C, $241E, $241D, $2454, $242D
    .dw $2428, $2454, $242D, $241A, $2424, $241E, $2454, $2430
    .dw $241A, $2425, $2424, $242C, $2455
    .dw $2454, $2454, $2454, $2454, $2454, $2454, $2454, $2454
    .dw $2454

    ; Row 25: "sometimes as late as 3:00AM."
    .dw $2454, $2454
    .dw $242C, $2428, $2426, $241E, $242D, $2422, $2426, $241E
    .dw $242C, $2454, $241A, $242C, $2454, $2425, $241A, $242D
    .dw $241E, $2454, $241A, $242C, $2454, $2437, $2452, $2434
    .dw $2434, $2400, $240C, $243E
    .dw $2454, $2454
@message_end:

    SCREEN01_TEXT_BLANK_ROW ; 26
    SCREEN01_TEXT_BLANK_ROW ; 27

    ; Rows 28-31 are outside the standard 224-line visible area.
    SCREEN01_TEXT_BLANK_ROW ; 28
    SCREEN01_TEXT_BLANK_ROW ; 29
    SCREEN01_TEXT_BLANK_ROW ; 30
    SCREEN01_TEXT_BLANK_ROW ; 31
@end:

screen01_text_map_count:
    .dw 1024
