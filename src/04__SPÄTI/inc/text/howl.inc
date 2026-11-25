; A transparent, high-priority space tile. One row is 32 tiles wide.
.MACRO HOWL_BLANK_ROW
    .dw $2454, $2454, $2454, $2454, $2454, $2454, $2454, $2454
    .dw $2454, $2454, $2454, $2454, $2454, $2454, $2454, $2454
    .dw $2454, $2454, $2454, $2454, $2454, $2454, $2454, $2454
    .dw $2454, $2454, $2454, $2454, $2454, $2454, $2454, $2454
.ENDM

howl:
    ; Blank rows 0-24 put the text on the bottom three visible rows.
    HOWL_BLANK_ROW ; 00
    HOWL_BLANK_ROW ; 01
    HOWL_BLANK_ROW ; 02
    HOWL_BLANK_ROW ; 03
    HOWL_BLANK_ROW ; 04
    HOWL_BLANK_ROW ; 05
    HOWL_BLANK_ROW ; 06
    HOWL_BLANK_ROW ; 07
    HOWL_BLANK_ROW ; 08
    HOWL_BLANK_ROW ; 09
    HOWL_BLANK_ROW ; 10
    HOWL_BLANK_ROW ; 11
    HOWL_BLANK_ROW ; 12
    HOWL_BLANK_ROW ; 13
    HOWL_BLANK_ROW ; 14
    HOWL_BLANK_ROW ; 15
    HOWL_BLANK_ROW ; 16
    HOWL_BLANK_ROW ; 17
    HOWL_BLANK_ROW ; 18
    HOWL_BLANK_ROW ; 19
    HOWL_BLANK_ROW ; 20
    HOWL_BLANK_ROW ; 21
    HOWL_BLANK_ROW ; 22


    ; Row 25: "I SAW THE BEST MINDS OF MY" (2-tile left inset).
    .dw $2454, $2454
    .dw $2408, $2454, $2412, $2400, $2416, $2454, $2413, $2407
    .dw $2404, $2454, $2401, $2404, $2412, $2413, $2454, $240C
    .dw $2408, $240D, $2403, $2412, $2454, $240E, $2405, $2454
    .dw $240C, $2418
    .dw $2454, $2454, $2454, $2454

    ; Row 26: "GENERATION DESTROYED BY" (no broken words).
    .dw $2454, $2454
    .dw $2406, $2404, $240D, $2404, $2411, $2400, $2413, $2408
    .dw $240E, $240D, $2454, $2403, $2404, $2412, $2413, $2411
    .dw $240E, $2418, $2404, $2403, $2454, $2401, $2418
    .dw $2454, $2454, $2454, $2454, $2454, $2454, $2454

    ; Row 27: "MADNESS" stays together on the final visible row.
    .dw $2454, $2454
    .dw $240C, $2400, $2403, $240D, $2404, $2412, $2412
    .dw $2454, $2454, $2454, $2454, $2454, $2454, $2454, $2454
    .dw $2454, $2454, $2454, $2454, $2454, $2454, $2454, $2454
    .dw $2454, $2454, $2454, $2454, $2454, $2454, $2454

        HOWL_BLANK_ROW ; 23
    HOWL_BLANK_ROW ; 24

    ; Rows 28-31 are offscreen but included to initialize the full 32x32 map.
    HOWL_BLANK_ROW ; 28
    HOWL_BLANK_ROW ; 29
    HOWL_BLANK_ROW ; 30
    HOWL_BLANK_ROW ; 31
howl_end:

howl_count:
    .dw 1024
