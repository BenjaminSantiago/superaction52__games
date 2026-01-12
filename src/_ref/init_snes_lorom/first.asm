;include statements
;------------------------------------------
.INCLUDE "header.inc"
.INCLUDE "InitSNES.asm"

;where to put this section of code
;------------------------------------------
.BANK   0   SLOT 0
.ORG    0
.SECTION "MainCode"

;------------------------------------------
Start:
    InitSNES            

    ;designate color no.0
    stz $2121         
                        
    ;first byte of color (5E28)
    lda #$28    
    sta $2122

    lda #$5E
    sta $2122

    ;turn on the screen
    lda #$0F
    sta $2100      

;loop
;------------------------------------------
forever:
    jmp forever

.ENDS