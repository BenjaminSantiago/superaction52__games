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
; $0000 - $0200 -> virtual OAM low
; $0200 - $0220 -> virtual OAM high
; NEED TO ACCOUNT FOR DIRECT PAGE

; CONTROLLER
; c --> "current"
; p --> "pressed" this frame
; h --> "held" from previous frame

; renumber this!
;-------------------------------
.EQU joy1H__c   $022E
.EQU joy1H__p   $022F
.EQU joy1H__h   $0230

.EQU joy1L__c   $0231
.EQU joy1L__p   $0232
.EQU joy1L__h   $0233

.EQU joy2H__c   $0234
.EQU joy2H__p   $0235
.EQU joy2H__h   $0236

.EQU joy2L__c   $0237
.EQU joy2L__p   $0238
.EQU joy2L__h   $0239
;-------------------------------

; bit flags
;-------------------------------
;0 --> 1
;1 --> 2
.EQU current__PLAYER        $0241

.EQU is_GAME_paused         $0274
;-------------------------------

; $2100, the register for this 
; can only be read so we need a variable to hold this
.EQU SCREEN__brightness     $0245


.EQU rng                    $4269

; game modes
;-------------------------------
; 00 --> title
; 01 --> options? 
; 02 --> game -> adventure mode
; 03 --> game -> memorize mode
; 04 --> game -> instrument mode
; 05 --> game -> adventure mode --> tutorial
; 06 --> game -> game over -> win
; 07 --> game -> game over -> loss
.EQU    gameMODE    $0221

; HDMA reads this table during rendering, so keep it away from
; OAM shadow RAM ($0000-$021F) and normal game variables.
.EQU HDMA_table  $0300
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

    ; TILE MAPS
    ;------------------------------------------------------
    ; increment after writing to $2119
    lda #$80
    sta $2115

    ; tilemap offset --> $1000
    ; tilemap size   --> 1 screen in either direction
    lda #$10
    sta $2107
    
    ; tilemap offset --> $1800
    ; tilemap size   --> 1 screen in either direction
    lda #$18
    sta $2108 
    
    ; DMA the tile maps
    LoadBlockToVRAM tilemap__BG02__drop, $1000, 1024 
    LoadBlockToVRAM tilemap__BG01, $1800, 1024
    ;------------------------------------------------------

    ; SPRITES
    ;------------------------------------------------------
    jsr SpriteInit

    ;16x16 and 32x32 sprites 
    ;address offset
    lda #%01100001          
    sta $2101
    ;------------------------------------------------------

    ; START IT UP!
    ;------------------------------------------------------
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

    lda $4210
    sta rng
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
;    stz $4300
;
;    lda #$04
;    sta $4301
;
;    lda #$00
;    sta $4302
;    sta $4303
;
;    lda #$7E
;    sta $4304
;
;    lda #$20
;    sta $4305
;    lda #$02
;    sta $4306
;
;    lda #$01
;    sta $420B
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
    ;-------------------------------------

    ;HDMA stuff
    ;-------------------------------------
;    stz $210D
;    stz $210D
;
;    lda #$02
;    sta $420C
;
;    lda $4210
    ;-------------------------------------

    ;PAUSE processing
    ;-------------------------------------
PAUSE_processing:
    lda is_GAME_paused
    beq @check_bright

    ; game is paused
    ; dim screen
@check_dim:
    lda SCREEN__brightness
    cmp #$08
    bne @dim_screen

    bra @done_with_PAUSE
    
@dim_screen:
    dec SCREEN__brightness
    lda SCREEN__brightness
    sta $2100
    bra @done_with_PAUSE
    
@check_bright:
    lda SCREEN__brightness
    cmp #$0F
    beq  @done_with_PAUSE

@brighten_screen:
    inc SCREEN__brightness
    lda SCREEN__brightness
    sta $2100
@done_with_PAUSE:

end_interrupt:
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

;-----------------------------
refresh_RNG:

    lda rng
    asl 
    bcc +
    eor #$1D
    +   
    sta rng

    rts
;-----------------------------

;---------------------------------------------------------------
.ENDS

; graphics
;---------------------------------------------------------------
.BANK 1 SLOT 0
.ORG 0
.SECTION "graphic_and_audio__includes"


;---------------------------------------------------------------
.ENDS
