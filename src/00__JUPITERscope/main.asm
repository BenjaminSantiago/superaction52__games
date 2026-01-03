;---------------------------------------------------------------
; SUPER ACTION 52 --> WEEK 01 --> JUPITER SCOPE
; by Benjamin Santiago
;---------------------------------------------------------------

;includes
;---------------------------------------------------------------
;header for this ROM
.INCLUDE "inc/header.inc"

;code to start up SNES (clear registers)
;and macros for graphics
.INCLUDE "inc/init.inc"
;.INCLUDE "inc/load_graphics.asm"

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
                        
    ;first byte of color 
    lda #$28    
    sta $2122

    lda #$53
    sta $2122

    ;turn on the screen
    lda #$0F
    sta $2100      


;loop
;------------------------------------------
forever:
    jmp forever

.ENDS