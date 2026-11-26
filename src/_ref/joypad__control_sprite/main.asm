;move sprite with controller
;by Benjamin Santiago
;---------------------------------------------------------------

;includes
;---------------------------------------------------------------
;header for this ROM
.INCLUDE "inc/header.inc"

;code to start up SNES (clear registers)
;and macros for graphics
.INCLUDE "inc/init.inc"
.INCLUDE "inc/load_graphics.asm"

.INCLUDE "../../__inc/registers.inc"

;VARIABLES
;---------------------------------------------------------------
;sprites go from $0000 - $0220

;these two are to determine if the sprite should go 
;go back or forth in each dimension
.EQU Y_dir      $0221
.EQU X_dir      $0222

;variables for controller
.EQU joy1H__c   $0223
.EQU joy1H__p   $0224
.EQU joy1H__h   $0225

.EQU s1_speed   $0226

;where the processor goes on reset
;---------------------------------------------------------------
.BANK 0 SLOT 0
.ORG 0
.SECTION "MainCode"

Start:
    ;start up the SNES
    InitSNES   

    ;"initialize" the "variables"
    ;---------------------------------------------
    stz X_dir
    stz Y_dir

    lda #$04
    sta s1_speed

    ;A/X/Y width (XY 16-bit & A 8-bit)   
    rep #$10    
    sep #$20

    ;BG MODE / character size
    ;2105.b0    --> bg mode 1
    ;2015.b3    --> character priority
    lda #%00001001
    sta BGMODE

    ;initial bg color (0th color is white $7FFF)
    ;---------------------------------------------
    stz CGADD
    lda #$FF
    sta CGDATA
    lda #$7F
    sta CGDATA
    
    ; Load Palette for our tiles
    ;---------------------------------------------
    ; Sprite Palettes start at color 128
    LoadPalette SprPal, 128, 16     

    ; Load Tile data to VRAM
    ;---------------------------------------------
    LoadBlockToVRAM Sprite, $0000, $0800

    ;initialize sprites
    ;---------------------------------------------
    ;put RAM "copy" of sprites offscreen
    jsr SpriteInit    

    ;initialize sprite properties
    ;set x (screen *.5 / width of sprite*.5)
    lda #(256/2 - 16)
    sta $0000
    
    ;set y (screen.height * .5/height of sprite*.5)
    lda #(224/2 - 16)
    sta $0001
    
    ;first sprite is zeroth one
    stz $0002

    ;sprite_byte_3.b6   --> horizontal flip
    ;sprite_byte_3.b4-5 --> sprite priority 3 (above bgs?)
    lda #%00110000
    sta $0003
    
    ;enable 9th x-bits
    lda #%01010100
    sta $0200
    
    ; Setup Video modes and other stuff, then turn on the screen
    jsr SetupVideo

    ;enable NMI and enable joypad
    lda #$81
    sta NMITIMEN

;main loop
;---------------------------------------------------------------
Infinity:
    wai 

;check directional controls
;---------------------------------------------
_up_check:
    lda joy1H__h
    and #%00001000
    bne +

    bra _down_check
+
    lda $0001
    sec
    sbc s1_speed
    sta $0001

_down_check:
    lda joy1H__h
    and #%00000100
    bne +

    bra _left_check
+
    lda $0001
    clc
    adc s1_speed
    sta $0001   

_left_check:
    lda joy1H__h
    and #%00000010
    bne +

    bra _right_check
+
    lda $0000
    sec
    sbc s1_speed
    sta $0000

    ;check if the carry bit is cleared via subtraction
    ;prevent the sprite from disappearing when it's left
    ;edge hits the left side of the screen
    bcc +

    bra _test_left_edge

+   lda #%01010101
    sta $0200

_test_left_edge:
    lda $0000
    cmp #$E0
    bcc +

    bra _right_check

+   lda $0200
    cmp #%01010101
    beq +

    bra _right_check

+   lda #$FF
    sta $0000

    lda #%01010100
    sta $0200

_right_check:
    lda joy1H__h
    and #%00000001
    bne +

    bra Infinity
+
    lda $0000
    clc
    adc s1_speed
    sta $0000

    ;check carry bit for same reason as for subtraction
    bcs +

    jmp _test_right_edge

+   lda #%01010100
    sta $0200

_test_right_edge:
    ;test if sprite 1 is at $0FF
    lda $0000
    cmp #$FF
    beq +

    jmp Infinity

+   lda $0200
    cmp #%01010100
    beq +

    jmp Infinity

+
    lda #$E0
    sta $0000

    lda #%01010101
    sta $0200

    jmp Infinity    ;<-- we outttttt t t t t t t t
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
    
    ;transfer sprite data into OAM
    ;----------------------------------
    ; set OAM address to 0
	stz OAMADDL		
	stz OAMADDH

    ; CPU -> PPU, auto increment, write 1 reg, $2104 (OAM Write)
	LDY #$0400
	STY DMAP0		

    ; source offset
	stz A1T0L 
    stz A1T0H		

    ; number of bytes to transfer
	LDY #$0220
	STY DAS0L		

    ; bank address = $7E  (work RAM)
	LDA #$7E
	STA A1B0		

    ; start DMA transfer
	LDA #$01
	STA MDMAEN		
	
	lda #%10100000
    sta OBJSEL

    ;Enable BG1
    lda #%00010000      
    sta TM
    
    ;Turn on screen, full Brightness
    lda #$0F
    sta INIDISP          

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

    lda RDNMI

    ply
    plx
    pla
	
    sep #$20
    rti

;---------------------------------------------------------------
.ENDS

;face graphic and palette
;---------------------------------------------------------------
.BANK 1 SLOT 0
.ORG 0
.SECTION "CharacterData"

Sprite:
    .INCBIN "img/face__32x32__.pic"

SprPal:
    .INCBIN "img/face__32x32__.clr"
;---------------------------------------------------------------
.ENDS
