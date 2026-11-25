; 32x32 SNES BG tilemap generated from text.
; Visible screen: 32x28 8x8 tiles; border: 2 columns x 2 rows.
; Font indices: $00-$19=A-Z, $1A-$33=a-z, $34-$3D=0-9.
; $3E=. $3F=! $40=? $41=" $42=# $43=$ $44=% $45=& $46=' $47=( $48=)
; $49=* $4A=+ $4B=left quote (`) $4C=- $4D== $4E=/ $4F=\ $50=> $51=< $52=: $53=; $54=space $55=,.
; Tile offset: $000; palette: 1; priority: 1; hflip: 0; vflip: 0.
.MACRO SCREEN02_TEXT_MAP_BLANK_ROW
    .dw $2454, $2454, $2454, $2454, $2454, $2454, $2454, $2454
    .dw $2454, $2454, $2454, $2454, $2454, $2454, $2454, $2454
    .dw $2454, $2454, $2454, $2454, $2454, $2454, $2454, $2454
    .dw $2454, $2454, $2454, $2454, $2454, $2454, $2454, $2454
.ENDM

screen02_text_map:
@begin:
    SCREEN02_TEXT_MAP_BLANK_ROW ; row 00: border
    SCREEN02_TEXT_MAP_BLANK_ROW ; row 01: border
    SCREEN02_TEXT_MAP_BLANK_ROW ; row 02: before text
    SCREEN02_TEXT_MAP_BLANK_ROW ; row 03: before text
    SCREEN02_TEXT_MAP_BLANK_ROW ; row 04: before text
    SCREEN02_TEXT_MAP_BLANK_ROW ; row 05: before text
    SCREEN02_TEXT_MAP_BLANK_ROW ; row 06: before text
    SCREEN02_TEXT_MAP_BLANK_ROW ; row 07: before text
    SCREEN02_TEXT_MAP_BLANK_ROW ; row 08: before text
    SCREEN02_TEXT_MAP_BLANK_ROW ; row 09: before text
    SCREEN02_TEXT_MAP_BLANK_ROW ; row 10: before text
    SCREEN02_TEXT_MAP_BLANK_ROW ; row 11: before text
    SCREEN02_TEXT_MAP_BLANK_ROW ; row 12: before text
    SCREEN02_TEXT_MAP_BLANK_ROW ; row 13: before text
    SCREEN02_TEXT_MAP_BLANK_ROW ; row 14: before text
    SCREEN02_TEXT_MAP_BLANK_ROW ; row 15: before text
    SCREEN02_TEXT_MAP_BLANK_ROW ; row 16: before text
    SCREEN02_TEXT_MAP_BLANK_ROW ; row 17: before text
    SCREEN02_TEXT_MAP_BLANK_ROW ; row 18: before text
    SCREEN02_TEXT_MAP_BLANK_ROW ; row 19: before text
    SCREEN02_TEXT_MAP_BLANK_ROW ; row 20: before text
    SCREEN02_TEXT_MAP_BLANK_ROW ; row 21: before text
    SCREEN02_TEXT_MAP_BLANK_ROW ; row 22: before text
    SCREEN02_TEXT_MAP_BLANK_ROW ; row 23: before text
@message_begin:
    ; Row 24: "Really long walks, trying to"
    .dw $2454, $2454, $2411, $241E, $241A, $2425, $2425, $2432 ; columns 00-07: "  Really"
    .dw $2454, $2425, $2428, $2427, $2420, $2454, $2430, $241A ; columns 08-15: " long wa"
    .dw $2425, $2424, $242C, $2455, $2454, $242D, $242B, $2432 ; columns 16-23: "lks, try"
    .dw $2422, $2427, $2420, $2454, $242D, $2428, $2454, $2454 ; columns 24-31: "ing to  "
    ; Row 25: "see how far I could go."
    .dw $2454, $2454, $242C, $241E, $241E, $2454, $2421, $2428 ; columns 00-07: "  see ho"
    .dw $2430, $2454, $241F, $241A, $242B, $2454, $2408, $2454 ; columns 08-15: "w far I "
    .dw $241C, $2428, $242E, $2425, $241D, $2454, $2420, $2428 ; columns 16-23: "could go"
    .dw $243E, $2454, $2454, $2454, $2454, $2454, $2454, $2454 ; columns 24-31: "        "
@message_end:
    SCREEN02_TEXT_MAP_BLANK_ROW ; row 26: border
    SCREEN02_TEXT_MAP_BLANK_ROW ; row 27: border
    SCREEN02_TEXT_MAP_BLANK_ROW ; row 28: outside visible screen
    SCREEN02_TEXT_MAP_BLANK_ROW ; row 29: outside visible screen
    SCREEN02_TEXT_MAP_BLANK_ROW ; row 30: outside visible screen
    SCREEN02_TEXT_MAP_BLANK_ROW ; row 31: outside visible screen
@end:

screen02_text_map_count:
    .dw 1024
