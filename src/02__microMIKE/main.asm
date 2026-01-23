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
.EQU MIKE__x    $0221
.EQU MIKE__y    $0222
.EQU MIKE__spr  $0223

.EQU fallSPEED $0224
;---------------------------------------------------------------

;where the processor goes on reset
;---------------------------------------------------------------
.BANK 0 SLOT 0
.ORG 0
.SECTION "MainCode"

Start:
    ;start up the SNES
    InitSNES   

    ;"initialize" the "variables"
    lda #$80
    sta MIKE__x
    sta MIKE__y

    lda #$00
    sta MIKE__spr

    lda #$02
    sta fallSPEED

    jsr InitSoundCPU

    ;A/X/Y width (XY 16-bit & A 8-bit)   
    rep #$10    
    sep #$20

    ; BG Mode
    ; BG mode 01
    ; BG Layer 1 character size 16x16
    lda #%00010001
    sta $2105

    ; Load Palette for our tiles
    LoadPalette bg__palette, 0, 16
    ; Sprite Palettes start at color 128!
    LoadPalette sprite__palette, 128, 16     

    ; Load Tile data to VRAM
    LoadBlockToVRAM bg__tiles, $0000, $0400
    LoadBlockToVRAM sprite__tiles, $1000, $0400

    ;put RAM "copy" of sprites offscreen
    jsr SpriteInit    
    
    lda MIKE__x
    sta $0000

    lda MIKE__y
    sta $0001

    lda MIKE__spr
    sta $0002

    lda #%00110001
    sta $0003
    
    lda #%00000010
    sta $0200

    ; Setup Video modes and other stuff, then turn on the screen
    jsr SetupVideo

    ; Enable NMI
    lda #$80
    sta $4200       

;main loop
;---------------------------------------------------------------
FOREVER:
    wai;t for interrupt

    lda MIKE__y 
    cmp #$F0
    bcc +

    lda #$02
    sta fallSPEED

+
    ; "gravity"
    inc fallSPEED
    lda MIKE__y
    clc 
    adc fallSPEED
    sta MIKE__y
    sta $0001

    
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

InitSoundCPU:
    php
    pha
    phx

    rep #$30
    sep #$20

    ;initialize transfer
    ;------------------------------------------------------
    ;make sure #$AA and #$BB are at $2140 and $2141 
    ;respectively. this is makes sure that the SPC is ready
    ;the original code didn't do this but worked fine
    lda #$AA
-
    cmp $2140
    bne -
-
    lda #$BB
    cmp $2141
    bne -   
    
    ldx #$0400      ;Target SPC address for program, why #$400?
                    ;(because that's where SPCTEST.asm "orgs" to)
    stx $2142       ;why port 2 --> port 2 is address for data

    lda #$01        ;what is 1  --> value to initialize transfer
    sta $2141       ;why port 1 --> port 1 is status of transfer

    ;wait for SPC sync
    ;when you read CC on 2140 from SPC
    ;everything is good
    lda #$CC
    sta $2140
-       cmp $2140       
    bne -

    plx
    pla
    plp
    rts
    ;------------------------------------------------------


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
	
	lda #%00000000
    sta $2101

    ; enable bg and sprites
    lda #%00010000      
    sta $212C
    
    
    lda #$0F
    sta $2100           ;Turn on screen, full Brightness

    plp
    rts



;NMI (vblank) code
;---------------------------------------------------------------
VBlank:
	pha
	phx
	phy
    
    rep #$10    
    sep #$20

pre_setup:    

    jsr SetupVideo
    
	PLY 
	PLX 
	PLA 

    sep #$20
    RTI

;---------------------------------------------------------------
.ENDS

;face graphic
;---------------------------------------------------------------
.BANK 1 SLOT 0
.ORG 0
.SECTION "graphic_and_audio__includes"

bg__palette: 
    .incbin "_graphics/MICROmike__bg__proto.clr"
sprite__palette:
    .incbin "_graphics/MICROmike__v01.clr"
bg__tiles:
    .incbin "_graphics/MICROmike__bg__proto.pic"
sprite__tiles:
    .incbin "_graphics/MICROmike__v01.pic"


;---------------------------------------------------------------
.ENDS
