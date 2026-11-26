;---------------------------------------------------------------
; BLANK SNES game TEMPLATE
; by Benjamin Santiago

; description: 
;---------------------------------------------------------------

;includes
;---------------------------------------------------------------
;header for this ROM
.INCLUDE "inc/header.inc"

;code to start up SNES (clear registers)
;and macros for graphics
.INCLUDE "inc/init.inc"
.INCLUDE "inc/load_graphics.asm"

;"variables" and aliases
;---------------------------------------------------------------
; random-ness if needed
.EQU rng            $0000

; controller values
; c is "current"
; p is "pressed"    (as in newly pressed since last read)
; h is "held"       (as in, held since the last read)
.EQU joy1H__c       $0000
.EQU joy1H__p       $0000
.EQU joy1H__h       $0000
.EQU joy1L__c       $0000
.EQU joy1L__p       $0000
.EQU joy1L__h       $0000

.EQU joy2H__c       $0000
.EQU joy2H__p       $0000
.EQU joy2H__h       $0000
.EQU joy2L__c       $0000
.EQU joy2L__p       $0000
.EQU joy2L__h       $0000
;---------------------------------------------------------------

;where the processor goes on reset
;---------------------------------------------------------------
.BANK 0 SLOT 0
.ORG  0
.SECTION "MainCode"

Start:
    ;start up the SNES
    INIT__snes 

    ;"initialize" the "variables"
    ;---------------------------------
    stz rng
    ;---------------------------------

    ;A/X/Y width (XY 16-bit & A 8-bit)   
    rep #$10    
    sep #$20

    ; Load Palettes & Graphics
    ;---------------------------------
    ;LoadPalette XXXX, 0,   16
    ;LoadPalette XXXX, 128, 16
    ;LoadBlockToVRAM sprite, $0000, $0800
    ;---------------------------------

    ;put WRAM "copy" of sprites offscreen
    jsr SETUP__sprites  

    ; Setup video modes and other stuff
    jsr SETUP__video

    ; bg priorities
    ; and character sizes
    lda #%00000000
    sta BGMODE    

    ; sprite sizes 
    ; sprite vram offsets
	lda #%00000000
    sta OBJSEL

    ; enable background layers
    ; enable sprites
    lda #%00000000      
    sta TM
    
    ;Turn on screen, full Brightness
    lda #$0F
    sta INIDISP        

    ; Enable NMI
    ; and joypad
    lda #%10000001
    sta NMITIMEN      

;main loop
;---------------------------------------------------------------
FOREVER:
    wai;t for interrupt

    ;refresh the rng
    ;-----------------------------------------
    lda rng
    asl 
    bcc +
    eor #$1D
+   
    sta rng
    ;-----------------------------------------


    jmp FOREVER    ;<-- we outttttt t t t t t t t
;---------------------------------------------------------------


;S U B R O U T I N E S

;initialize the sprites to be off-screen
;(this is only in RAM, still has to be 
;transferred to the OAM)
;---------------------------------------------------------------
SETUP__sprites:
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
SETUP__video:
    php
    
    ;set XY/A
    rep #$10
    sep #$20
       
    ;DMA transfer sprite data into OAM
    ;----------------------------------
    ; set OAM address to $0000
	stz OAMADDL		
	stz OAMADDH

    ; CPU -> PPU, auto increment, write 1 reg, $2104 (OAM Write)
	ldy #$0400
	sty DMAP0		

    ; source offset
    stz A1T0L
	stz A1T0H		

    ; number of bytes to transfer
    ldy #$0220
	sty DAS0L 		

    ; bank address = $7E  (work RAM)
	lda #$7E
	sta A1B0		

    ;start DMA transfer
	lda #$01
	sta MDMAEN		
	;----------------------------------

    plp
    rts
;---------------------------------------------------------------


;NMI (vblank) interrupt code
;---------------------------------------------------------------
VBlank:
	pha
	phx
	phy
    
    rep #$10    
    sep #$20

    jsr SETUP__video

    ;READ controllers
    ;-----------------------------
    ;get joypad status    
-
    lda HVBJOY
    and #$01
    bne -
    
    ;read controller 1 high
    ;get previous input
    ldy joy1H__c

    ;get current input
    lda JOY1H
    ;store in c for "current"
    sta joy1H__c

    ;put previous value into accumulator
    tya 
    ;get any presses where the previous
    ;and current differ
    eor joy1H__c
    ;compare that result with current
    ;get anything that is newly pressed
    and joy1H__c
    ;store in p for "pressed"
    sta joy1H__p

    ;bring back the previous state
    tya 
    ;and to get anything the same
    ;between previous and current frame
    and joy1H__c
    ;store in h for "held"
    sta joy1H__h

    ;read controller 1 low
    ldy joy1L__c
    lda JOY1L
    sta joy1L__c
    tya 
    and joy1L__c
    eor joy1L__c
    sta joy1L__p
    tya 
    and joy1L__c
    sta joy1L__h

    ;read controller 2 high
    ldy joy2H__c
    lda JOY2H
    sta joy2H__c
    tya 
    eor joy2H__c
    and joy2H__c
    sta joy2H__p
    tya 
    and joy2H__c
    sta joy2H__h

    ;read controller 2 low
    ldy joy2L__c
    lda JOY2L
    sta joy2L__c
    tya 
    eor joy2L__c
    and joy2L__c
    sta joy2L__p
    tya 
    and joy2L__c
    sta joy2L__h

    lda RDNMI
    ;-----------------------------
    
	ply
    plx
    pla

    rti

;---------------------------------------------------------------
.ENDS

;GRAPHIC & AUDIO INCLUDES
;---------------------------------------------------------------
.BANK 1 SLOT 0
.ORG 0
.SECTION "graphic_and_audio__includes"


;---------------------------------------------------------------
.ENDS
