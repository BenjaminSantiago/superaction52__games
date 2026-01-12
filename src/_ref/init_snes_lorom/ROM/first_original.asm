;== Include memorymap, header info, and SNES initialization routines
.INCLUDE "header.inc"
.INCLUDE "InitSNES.asm"

;========================
; Start
;========================
.EQU CGRAM_Addr         $2121
.EQU CGRAM_DataWrite    $2122
.EQU Screen_Display     $2100

.BANK 0 SLOT 0
.ORG 0
.SECTION "MainCode"

Start:
    InitSNES            ; initialize the Super Nintendo. 
    					; (don't worry about this for now).

    stz CGRAM_Addr         ; store 0 in 2121. 2121 is the Color selection register.
    					   ; color 0 is the background color.
                        
    lda #%11100000          ; the color we want to store (green)
    sta CGRAM_DataWrite		; send the color the "color data register" 2122
    					   ; the color goes in like this: ?bbbbbgg gggrrrrr
    lda #%00000011          ; (the latter byte first)
    sta CGRAM_DataWrite

    lda #%00001111      ; now turn on the screen maximum brightness. 
    sta Screen_Display         
    

forever:
    jmp forever

.ENDS