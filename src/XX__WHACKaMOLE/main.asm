
;includes
;---------------------------------------------------------------
;header for this ROM
.INCLUDE "inc/header.inc"

;code to start up SNES (clear registers)
;and macros for graphics
.INCLUDE "inc/init.inc"
.INCLUDE "inc/load_graphics.asm"

;variables
;---------------------------------------------------------------

;---------------------------------------------------------------

;where the processor goes on reset
;---------------------------------------------------------------
.BANK       0 SLOT 0
.ORG        0
.SECTION    "MainCode"

Start:
    ;start up the SNES
    InitSNES   

    ;"initialize" the "variables"
    ;---------------------------------

    ;A/X/Y width (XY 16-bit & A 8-bit)   
    rep #$10    
    sep #$20

    lda #%00001001
    sta $2105
   
    ; Load Palettes & Graphics
    ;---------------------------------
    ;LoadPalette XXXX, 0,   16
    ;LoadPalette XXXX, 128, 16
    ;LoadBlockToVRAM sprite, $0000, $0800
    ;---------------------------------

    ;put RAM "copy" of sprites offscreen
    jsr SpriteInit    
    
    ; Setup Video modes and other stuff, then turn on the screen
    jsr SetupVideo

    ; Enable NMI
    lda #$81
    sta $4200       

;main loop
;---------------------------------------------------------------
FOREVER:
    wai;t for interrupt

    
    jmp FOREVER    ;<-- we outttttt t t t t t t t
;---------------------------------------------------------------


;S U B R O U T I N E S

;initialize the sprites to be off-screen
;(this is only in RAM, still has to be 
;transferred to the OAM)
;---------------------------------------------------------------
SpriteInit:
	php	

	rep	#$30	;16bit mem/A, 16 bit X/Y
	
	ldx #$0000
    lda #$0001
_setoffscr:
    sta $0000,X
    inx
    inx
    inx
    inx
    cpx #$0200
    bne _setoffscr
;-------------------
	ldx #$0000
	lda #$5555
_clr:
	sta $0200, X		;initialize all sprites to be off the screen
	inx
	inx
	cpx #$0020
	bne _clr
;-------------------

	plp
	rts
;---------------------------------------------------------------


;set up the "general video"-type registers
;---------------------------------------------------------------
SetupVideo:
    php
    
    ;set XY/A
    rep #$10
    sep #$20
    
    stz $2102
    stz $2103
    
    ;transfer sprite data into OAM
    ;----------------------------------
	stz $2102		; set OAM address to 0
	stz $2103

	LDY #$0400
	STY $4300		; CPU -> PPU, auto increment, write 1 reg, $2104 (OAM Write)

	stz $4302

	stz $4303		; source offset

	LDY #$0220
	STY $4305		; number of bytes to transfer

	LDA #$7E
	STA $4304		; bank address = $7E  (work RAM)

	LDA #$01
	STA $420B		;start DMA transfer
	
	lda #%10100000
    sta $2101

    lda #%00010000      ;Enable BG1
    sta $212C
    
    lda #$0F
    sta $2100           ;Turn on screen, full Brightness

    plp
    rts
;---------------------------------------------------------------



;NMI (vblank) code
;---------------------------------------------------------------
VBlank:
	pha
	phx
	phy
    
    rep #$10    
    sep #$20

    ;-----------------------------------------


    ;-----------------------------------------
    
    sep #$20
	
    ply 
	plx 
	pla 

    rti

;---------------------------------------------------------------
.ENDS

;face graphic
;---------------------------------------------------------------
.BANK       1 SLOT 0
.ORG        0
.SECTION    "graphic_and_audio__includes"


;---------------------------------------------------------------
.ENDS
