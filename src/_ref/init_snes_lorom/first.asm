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
    ; routine to clear registers
    ; and establish default settings
    InitSNES            

    ;designate color no.0
    stz CGADD         
                        
    ;first byte of color (5E28)
    lda #$28    
    sta CGDATA

    lda #$5E
    sta CGDATA

    ;turn on the screen
    lda #$0F
    sta REG_DISPCNT    

;loop
;------------------------------------------
forever:
    jmp forever

.ENDS