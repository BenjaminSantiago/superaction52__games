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

;variables
;---------------------------------------------------------------
;these two are to determine if the sprite should go 
;go back or forth in each dimens`ion
.EQU Y_dir      $0221
.EQU X_dir      $0222

;this is a flag to determine if the background 
;should be blue or not
.EQU bg_flash   $0223

;counter to inc and compare to if bg should be flashing or not
.EQU bg_c       $0224

;variables for controller
.EQU joy1H__c   $0225
.EQU joy1H__p   $0226
.EQU joy1H__h   $0227

.EQU s1_speed   $0228



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
    stz bg_flash
    stz bg_c

    lda #$04
    sta s1_speed

    ;A/X/Y width (XY 16-bit & A 8-bit)   
    rep #$10    
    sep #$20

    ;2105       --> BG MODE / character size
    ;2105.b0    --> bg mode 1
    ;2015.b3    --> character priority (I think this puts sprites above BGs?)
    lda #%00001001
    sta $2105

    ;initial bg color (white $7FFF)
    ;---------------------------------------------
    stz $2121
    lda #$FF
    sta $2122
    lda #$7F
    sta $2122
    
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
    ;set x (screen *.5 / width of sprite)
    lda #(256/2 - 16)
    sta $0000
    
    ;set y (screen.height * .5/height of sprite)
    lda #(224/2 - 16)
    sta $0001
    
    ;first tile is zeroth one
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
    sta $4200      



;main loop
;---------------------------------------------------------------
Infinity:
    wai 

    ;update values for background values
    ;---------------------------------------------
    ;see if bg_flash is 1 or 0
    lda bg_flash
    cmp #$01
    bne +

    ;see if counter is done
    lda bg_c
    cmp #$03
    bne for

    ;we are done so zero out counter
    ;and bg flash variable
    stz bg_c
    stz bg_flash
    bra +

for:
    ;(if counter isn't at the max, then inc)
    inc bg_c
+

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



;NMI (vblank) code
;---------------------------------------------------------------
VBlank:
	pha
	phx
	phy
    
    rep #$10    
    sep #$20

    ;----------------------------------------
    ;check if bg is flashing
    lda bg_flash
    cmp #$01
    bne +

    ;make BG blue ($72A5)
    stz $2121
    lda #$A5
    sta $2122
    lda #$72
    sta $2122
    jmp pre_setup

+
    ;otherwise set to white ($7FFF)
    stz $2121
    lda #$FF
    sta $2122
    lda #$7F
    sta $2122    

pre_setup:
    jsr SetupVideo

    ;get joypad status
-
    lda $4212
    and #$01
    bne -
    
    ;read controller 1 high
    ldy joy1H__c
    lda $4219
    sta joy1H__c
    tya 
    eor joy1H__c
    and joy1H__c
    sta joy1H__p
    tya 
    and joy1H__c
    sta joy1H__h

    lda $4210

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
.SECTION "CharacterData"


Sprite:
    .INCBIN "img/face__32x32__.pic"

SprPal:
    .INCBIN "img/face__32x32__.clr"
;---------------------------------------------------------------
.ENDS
