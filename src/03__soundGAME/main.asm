;init everything
;
;start on title
;
;    select mode --> adventure/instrument/memorize
;
;    l/r changes and then a or start selects (either control)
;
;    (load whatever for respective modes)
;    
;    memorize mode --> 
;        * stage loop
;            * show animals
;            * screen goes black
;            * respond to input (burst)
;            * show wrong right
;            * results 
;                * good wait for button to go to next
;                * bad try again or back to title
;        
;    adventure mode --> 
;        * decide if a new animal/button should be shown
;            * show it or go to stage
;        * stage loop
;            * show animals (only from available list)
;            * screen goes black
;            * respond to input (burst)
;            * show wrong right
;            * results 
;                * good wait for button to go to next (decide to show animal or not)
;                * bad try again or back to title
;
;    instrument mode --> 
;        * show all animals in grid
;        * respond to input
;        * maybe pause here is different and has the option to go back to title
;
;    * need to make where the heads show up is 
;        based on total. they are vertically centered.
;    * display level#
;
; * basic things to include: 
;    * bg code (decide mode(s))
;    * sprite display 
;    * controller input
;    * basic sound
;    * pause
;    * (game) modes

;---------------------------------------------------------------
; SUPER ACTION 52 --> WEEK 03 --> Sound Game
; by Benjamin Santiago
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

;---------------------------------------------------------------

; M A I N  C O D E
; where the processor goes on reset
;---------------------------------------------------------------
.BANK 0 SLOT 0
.ORG 0
.SECTION "MainCode"

Start:
    InitSNES

    ;"initialize" the "variables"
    ;------------------------------------------------------

    ; LOAD GRAPHICS
    ;------------------------------------------------------
    ;LoadPalette bg__palette,        0,      16 
    ;LoadBlockToVRAM bg__tiles,      $0000,  $1800
    ;------------------------------------------------------

    jsr SpriteInit

    ;16x16 and 32x32 sprites 
    ;address offset
    ;lda #%01100001          
    ;sta $2101

    jsr SetupVideo

    ; we want BG 1 & BG 2 to be 16 x 16
    ; we want BG mode 1
    lda #%00110001
    sta $2105

    ; BG1 & BG2 character VRAM offset
    stz $210B

    ldx #$0100
    stx $2110

    ; enable BG 1 & 2
    ; enable sprites
    lda #%00010011
    sta $212C
    
    ; enable interrupts
    lda #$81
    sta $4200    

    ;enable 9th x-bits / Embiggen sprites
    lda #%00001010
    sta $0200

    jsr InitHDMA
    ;------------------------------------------------------

;M A I N  L O O P! 
;---------------------------------------------------------------
forever:
    wai;t for an interrupt y'all!

    rep #$10
    sep #$20 

    jmp forever
;---------------------------------------------------------------
   

;S U B R O U T I N E S

;NMI (vblank) code
;---------------------------------------------------------------
VBlank:
    php
	pha
	phx
	phy    
    ;-----------------

    rep #$10    
    sep #$20
    
    ; "shadow OAM" --> actual OAM
    ;---------------------------------
    stz $4300

    lda #$04
    sta $4301

    lda #$00
    sta $4302
    sta $4303

    lda #$7E
    sta $4304

    lda #$20
    sta $4305
    lda #$02
    sta $4306

    lda #$01
    sta $420B
    ;---------------------------------

    ; CONTROLLERS
    ;-------------------------------------
    ; get joypad status
    ; wait until it is ready
-
    lda $4212
    and #$01
    bne -
    
    ;P1 
    ;---------------------------------
    ;read controller 1 high
    ;store current in Y (for p)
    ldy joy1H__c

    ;get current
    lda $4219
    sta joy1H__c

    ;switch
    tya 
    
    ;figure out new presses (p)
    ;figure out what was held (h)
    eor joy1H__c
    and joy1H__c
    sta joy1H__p
    tya 
    and joy1H__c
    sta joy1H__h

    ;read controller 1 high
    ;store current in Y (for p)
    ldy joy1L__c

    ;get current
    lda $4218
    sta joy1L__c

    ;switch
    tya 
    
    ;figure out new presses (p)
    ;figure out what was held (h)
    eor joy1L__c
    and joy1L__c
    sta joy1L__p
    tya 
    and joy1L__c
    sta joy1L__h

    ;P2
    ;---------------------------------
    ;read controller 2 high
    ;store current in Y (for p)
    ldy joy2H__c

    ;get current
    lda $421B
    sta joy2H__c

    ;switch
    tya 
    
    ;figure out new presses (p)
    ;figure out what was held (h)
    eor joy2H__c
    and joy2H__c
    sta joy2H__p
    tya 
    and joy2H__c
    sta joy2H__h

    ;read controller 2 high
    ;store current in Y (for p)
    ldy joy2L__c

    ;get current
    lda $421A
    sta joy2L__c

    ;switch
    tya 
    
    ;figure out new presses (p)
    ;figure out what was held (h)
    eor joy2L__c
    and joy2L__c
    sta joy2L__p
    tya 
    and joy2L__c
    sta joy2L__h

    ;HDMA stuff
    stz $210D
    stz $210D

    lda #$02
    sta $420C

    lda $4210

    lda is_GAME_paused
    beq +

    ; game is paused
    lda SCREEN__brightness
    cmp #$08
    bne @dim_screen

    jmp @end_interrupt
    
@dim_screen:
    dec SCREEN__brightness
    lda SCREEN__brightness
    sta $2100
    jmp @end_interrupt

+
    ;turn on screen
    ;(if not on)
    lda SCREEN__brightness
    cmp #$0F
    beq  +

    inc SCREEN__brightness
    lda SCREEN__brightness
    sta $2100
+

@check_connect_0:
    lda connections__PINK
    and #%00000001
    cmp #%00000001
    beq @process_pink_0

    bra @check_connect_1

@process_pink_0:
    rep #$20

    change_palette_in_tilemap $1847 71 %0000010000000000 
    change_palette_in_tilemap $1848 72 %0000010000000000 

    lda #$0000
    tax  
    sep #$20 
    
@check_connect_1:
    lda connections__PINK
    and #%00000010
    cmp #%00000010
    beq @process_pink_1
    
    jmp @check_connect_7

@process_pink_1:
    rep #$20

    change_palette_in_tilemap $184B 75 %0000010000000000 
    change_palette_in_tilemap $184C 76 %0000010000000000 

    lda #$0000  
    tax
    sep #$20 

@check_connect_7:
    lda connections__PINK
    and #%10000000
    cmp #%10000000
    beq @process_pink_7

    jmp @check_connect_8

@process_pink_7:
    rep #$20

    change_palette_in_tilemap $18C7 199 %0000010000000000 
    change_palette_in_tilemap $18C8 200 %0000010000000000 

    lda #$0000
    sep #$20
    
@check_connect_8:
    lda connections__PINK+1
    and #%00000001
    cmp #%00000001
    beq @process_pink_8

    jmp @check_connect_E

@process_pink_8:
    rep #$20

    change_palette_in_tilemap $18CB 203 %0000010000000000 
    change_palette_in_tilemap $18CC 204 %0000010000000000 

    lda #$0000
    sep #$20

@check_connect_E:
    lda connections__PINK+1
    and #%01000000
    cmp #%01000000
    beq @process_pink_E

    jmp @check_connect_F

@process_pink_E:
    rep #$20

    change_palette_in_tilemap $1947 327 %0000010000000000 
    change_palette_in_tilemap $1948 328 %0000010000000000 

    lda #$0000
    sep #$20

@check_connect_F:
    lda connections__PINK+1
    and #%10000000
    cmp #%10000000
    beq @process_pink_F

    bra @glow_up
@process_pink_F:
    rep #$20

    change_palette_in_tilemap $194B 331 %0000010000000000 
    change_palette_in_tilemap $194C 332 %0000010000000000 

    lda #$0000
    sep #$20

@glow_up:
    ;PALETTE GLOW
    ; we want to update
    ; $13 --> pink
    ; $23 --> blue
    ;----------------------------
    lda #$13
    sta $2121
    
    lda GLOW__current
    asl A
    tax 

    lda.l glow__pink, X
    sta $2122

    lda.l glow__pink + 1, x
    sta $2122

    lda GLOW__current
    cmp #$19
    bcc + 

    stz GLOW__current
    bra @end_interrupt

+   inc GLOW__current
    ;----------------------------
@end_interrupt:
    ;-----------------
	ply
    plx
    pla 
    plp
	
    sep #$20
    rti

;---------------------------------------------------------------

;initialize the sprites to be off-screen
;(this is only in RAM, still has to be 
;transferred to the OAM)
;---------------------------------------------------------------
SpriteInit:
	php	

	rep	#$30	;16bit mem/A, 16 bit X/Y
	
	ldx #$0000
    lda #$F001
_setoffscr:
    sta $0000,X
    inx
    inx
    inx
    inx
    cpx #$0200
    bne _setoffscr
;-------------------
	lda #$5555
_clr:
	sta $0000, X		;initialize all sprites to be off the screen
	inx
    inx
	cpx #$0220
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

    ; DMA params
    LDA #$00
    STA $4300      ; DMAP

    LDA #$04
    STA $4301      ; BBAD = $2104

    LDA #$00
    STA $4302
    STA $4303      ; source offset

    LDA #$7E
    STA $4304      ; source bank

    LDA #$20
    STA $4305
    LDA #$02
    STA $4306      ; $0220 bytes

    LDA #$01
    STA $420B      ; start DMA
    ;----------------------------------

    plp
    rts
;---------------------------------------------------------------

;---------------------------------------------------------------
.ENDS

; graphics
;---------------------------------------------------------------
.BANK 1 SLOT 0
.ORG 0
.SECTION "graphic_and_audio__includes"


;---------------------------------------------------------------
.ENDS
