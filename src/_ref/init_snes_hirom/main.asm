;== Include memorymap, header info, and SNES initialization routines
.INCLUDE "header.inc"
.INCLUDE "InitSNES.asm"

.BANK 0 SLOT 0
.ORG $F000
.SECTION "MainCode" SEMIFREE

Start:
    ;initialize the Super Nintendo. 
    ;(don't worry about this for now).
    init_snes           

    ;store 0 in 2121. 2121 is the Color selection register.
    ;color 0 is the background color.
    stz $2121     
    
    ;the color we want to store (green)                    
    lda #%11100000  
    ;send the color the "color data register" 2122        
    sta $2122		
    		
    ;send the rest of the color			  
    lda #%00000011        
    sta $2122

    ;send the color the "color data register" 2122
    lda #%00001111
    sta $2100 
    

forever:
    bra forever

.ENDS
;------------------------------------------------
