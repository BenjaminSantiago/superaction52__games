;---------------------------------------------------------------
; SUPER ACTION 52 --> WEEK 02 --> TAPATAN
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

; game modes
;-------------------------------
; 00 --> title
; 01 --> options? 
; 02 --> game -> drop phase
; 03 --> game -> move phase
; 04 --> game -> game over
.EQU    gameMODE    $0221

; The BOARD 
;-------------------------------
; it has 9 locations, 3 rows of 3. 
; each location is represented by 2 bits 
; empty         -> 00
; (p1) X occupied   ->  01
; (p2) O occupied   ->  10

; memory locations    
; 00 | 00 00 00 <-- $0222 TOP ROW
; 00 | 00 00 00 <-- $0223 MIDDLE ROW
; 00 | 00 00 00 <-- $0224 BOTTOM ROW
.EQU    BOARD_00    $0222 ; -> 0224
.EQU    BOARD_01    $0223
.EQU    BOARD_02    $0224
;-------------------------------

; how long to wait for sprite frames
.EQU    sprite__wait            $0225

; these should be for each coin
; counter for distance between sprites
; GET RID OF THIS 
;-------------------------------
.EQU    sprite__00__P1__counter $0226
; which sprite we show
.EQU    sprite__00__P1__sprite  $0227

; location
.EQU    sprite__00__P1__x       $0228
.EQU    sprite__00__P1__y       $0229

.EQU sprite__00__P2__counter    $022A
.EQU sprite__00__P2__sprite     $022B
.EQU sprite__00__P2__x          $022C
.EQU sprite__00__P2__y          $022D
;-------------------------------

; CONTROLLER
; c --> "current"
; p --> "pressed" this frame
; h --> "held" from previous frame
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

;HDMA pills
;-------------------------------
.EQU PILL__player__offset       $023A ;16-bit value, uses $023A-$023B
.EQU PILL__player__direction    $023C
;-------------------------------

;CURSOR
;-------------------------------
.EQU CURSOR__P1__x  $023D
.EQU CURSOR__P1__y  $023E

.EQU CURSOR__P2__x  $023F
.EQU CURSOR__P2__y  $0240

.EQU CURSOR__blink__counter $0243
.EQU CURSOR__blink__max     $0244
;-------------------------------

;0 --> 1
;1 --> 2
.EQU current__PLAYER        $0241

; $2100, the register for this 
; can only be read so we need a variable to hold this
.EQU SCREEN__brightness     $0245

;-------------------------------
;when we draw the board this is where we are 0 - 8
.EQU COIN__cell__index      $0246
.EQU COIN__sOAMoffset       $0247

;each COIN has a spriteINDEX
;meaning which sprite it is displaying
;this is from a table in memory

;each coin has a counter to measure
;wait between frames

;each coin stores how many frames it has
;(this is dumb but X and O animations
;are different lengths, not gonna
;optimize right now)
.EQU COIN__anim__counters       $0250 ; --> $0258, 9 bytes
.EQU COIN__anim__spriteINDEX    $0259 ; --> $0261, 9 bytes
.EQU COIN__anim__finalFRAME     $0262 ; --> $026A, 9 bytes
.EQU COIN__X_or_O               $026B ; --> $0273, 9 bytes
;-------------------------------

; HDMA reads this table during rendering, so keep it away from
; OAM shadow RAM ($0000-$021F) and normal game variables.
.EQU HDMA_table  $0300

; M A I N  C O D E
; where the processor goes on reset
;---------------------------------------------------------------
.BANK 0 SLOT 0
.ORG 0
.SECTION "MainCode"

Start:
    ;start up the SNES
    InitSNES   

    ;"initialize" the "variables"
    ;------------------------------------------------------
    stz SCREEN__brightness
    stz gameMODE
    stz BOARD_00
    stz BOARD_01
    stz BOARD_02

    stz sprite__00__P1__x
    stz sprite__00__P1__y
    stz sprite__00__P1__counter    
    stz sprite__00__P1__sprite

    stz sprite__00__P2__counter    
    stz sprite__00__P2__sprite

    stz PILL__player__offset
    stz PILL__player__direction

    stz current__PLAYER
    stz CURSOR__blink__counter

    stz COIN__cell__index

    lda #$03
    sta sprite__wait

    lda #$90
    sta CURSOR__P1__x
    sta CURSOR__P2__x
    
    lda #$60
    sta CURSOR__P1__y
    sta CURSOR__P2__y

    lda #$0A
    sta CURSOR__blink__max

    lda #$04
    sta COIN__sOAMoffset

    ;need to zero out all the board bits
    ;------------------------------------------------------

    ; LOAD GRAPHICS
    ;------------------------------------------------------
    LoadPalette bg__palette,        0,      16 
    LoadPalette sprites__palette,   128,    16
    LoadBlockToVRAM bg__tiles,      $0000,  $1800
    LoadBlockToVRAM sprites__tiles, $2000,  $3800
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

    jsr MAKE__HDMAtable
    jsr InitHDMA

    ;------------------------------------------------------


;M A I N  L O O P! 
;---------------------------------------------------------------
forever:
    wai;t for an interrupt y'all!

    rep #$10
    sep #$20 

    ;TITLE
    ;----------------------------------------------------------
    ; title game code 
    ; --> display title
    ;----------------------------------------------------------

    ;GAME 
    ;----------------------------------------------------------
@show__game__board:
    ;enable 9th x-bits / Embiggen sprites
    lda #%10101010
    sta $0200

    lda #%10101010
    sta $0201

    lda #%00001010
    sta $0202

    lda #$04
    sta COIN__sOAMoffset
    ;check each location to see if it is occupied
    ;if so by who?

    ;top row
    lda BOARD_00

    ;L
    and #%00110000
    beq @done_with_BOARD ;<-- if we get zero be out

    ;check X
    cmp #%00010000
    beq @COIN__is__X

    ;must be O
    ldx COIN__cell__index
    lda #$01
    sta COIN__X_or_O, X

    bra +
    
@COIN__is__X:
    ldx COIN__cell__index
    lda #$00
    sta COIN__X_or_O, X

+
    jsr draw__COIN

@done_with_BOARD:

@PILL__player__anim__intro:
    ; check direction 
    ; 0 is left, 1 is right
    lda PILL__player__direction
    cmp #$00
    bne move_right

    ; if 0 
    ; check if we are at the max 
    rep #$20
    lda PILL__player__offset
    cmp #$0040 
    bcc +
    sep #$20

    bra done_with_PILL

+   
    ; move to the left (adc)
    rep #$20
    lda PILL__player__offset
    clc 
    adc #$0001
    sta PILL__player__offset
    sta HDMA_table+1
    sep #$20
    bra done_with_PILL

 move_right:
    ; check if we are at #$00
    rep #$20
    lda PILL__player__offset
    cmp #$0000
    bne +
    sep #$20
    
    ; if 1
    ; if we are, change direction
    lda #$00
    sta PILL__player__direction
    bra done_with_PILL

    ; move to the right (sbc)
+   rep #$20
    lda PILL__player__offset
    sec 
    sbc #$0001
    sta PILL__player__offset
    sta HDMA_table+1
    sep #$20
    
 done_with_PILL:
    
    ; DISPLAY CURSOR
    ;---------------------------------
    ;set x (location 1)
 draw_cursor: 
    ;get current player
    ;shift because we have x and y 
    ;next to each other
    lda current__PLAYER
    asl a 
    tax

    ;transfer cursor location
    lda CURSOR__P1__x, X
    sta $0000

    lda CURSOR__P1__y, X
    dec a 
    sta $0001

    ;get tile based on table (below)
    lda current__PLAYER
    tax
    lda.l CURSOR__tile, X
    sta $0002

    ;process cursor blink
    lda CURSOR__blink__counter
    cmp CURSOR__blink__max
    beq +

    ;increment counter
    inc CURSOR__blink__counter
    bra check_controls

+   
    ;reset cursor
    stz CURSOR__blink__counter

    ;see if it is on screen 
    ;or not
    ;switch bit
    lda $0003
    and #%00000001
    beq +

    lda #%00110000
    sta $0003
    bra check_controls

+   lda #%00110001
    sta $0003
    bra check_controls

 check_controls:
    
 check__P1__UP:
    lda joy1H__p
    and #%00001000
    beq check__P1__DOWN

    ;---------------------------
    lda CURSOR__P1__y
    cmp #$20
    beq check__P1__DOWN

    lda CURSOR__P1__y
    sec
    sbc #$40
    sta CURSOR__P1__y
    ;---------------------------

 check__P1__DOWN:
    lda joy1H__p
    and #%00000100
    beq check__P1__LEFT

    ;---------------------------
    lda CURSOR__P1__y
    cmp #$A0
    beq check__P1__LEFT

    lda CURSOR__P1__y
    clc
    adc #$40
    sta CURSOR__P1__y
    ;---------------------------

 check__P1__LEFT:
    lda joy1H__p
    and #%00000010
    beq check__P1__RIGHT

    ;---------------------------
    lda CURSOR__P1__x
    cmp #$50
    beq check__P1__RIGHT

    lda CURSOR__P1__x
    sec
    sbc #$40
    sta CURSOR__P1__x
    ;---------------------------

 check__P1__RIGHT:
    lda joy1H__p
    and #%00000001
    beq check__P1__A
    
    ;---------------------------
    lda CURSOR__P1__x
    cmp #$D0
    beq check__P1__A

    lda CURSOR__P1__x
    clc
    adc #$40
    sta CURSOR__P1__x
    ;---------------------------
    
 check__P1__A:
    lda joy1L__p
    and #%10000000
    beq done_with_P1CONTROL

    ;x values
    ;$50, $90, $D0
    
    ;y values
    ;$20, $60, $A0

    ; memory locations    
    ; 00 | 00 00 00 <-- $0222 TOP ROW
    ; 00 | 00 00 00 <-- $0223 MIDDLE ROW
    ; 00 | 00 00 00 <-- $0224 BOTTOM ROW
  
    ; A PRESSED
    ;---------------------------
    ; set the sprite to start animating
    ;stz sprite__00__P1__counter    
    ;stz sprite__00__P1__sprite
        ; use x and y for...x and y
    ; sure there are better ways
    ; to do this, but there are 9
    ; locations so I need at least
    ; 9 bits so idk, just using
    ; the x and y

    ; for x --> 
    ; 00000011 --> LEFT
    ; 00001100 --> MIDDLE
    ; 00110000 --> RIGHT

    ; for y --> 
    ; 00 --> TOP
    ; 01 --> MIDDLE
    ; 02 --> BOTTOM
    ldx #$00
    ldy #$00

    ; get the cursor x
    lda CURSOR__P1__x

    ;left 
    cmp #$50
    bne +

    ldx #%00110000

+   ;middle
    lda CURSOR__P1__x
    cmp #$90
    bne +

    ldx #%00001100

+   ;assume right
    ldx #%00000011

    ; get the cursor y
 A__check__P1__y:
    ; top
    lda CURSOR__P1__y
    cmp #$20
    bne +

    ldy #$00

+   ; middle 
    lda CURSOR__P1__y
    cmp #$60
    bne +

    ldy #$01

+   ; bottom 
    ldy #$02

    ; use x & y to determine where in the
    ; "board bits" it will go
    ; make sure it is not already taken 

    txa 
    and BOARD_00, Y

    ; if it is not ZERO we will get out
    ; cell is occupied
    ; PUT SOMETHING TO SHOW "BAD" FEEDBACK
    bne done_with_P1CONTROL 
    
    ; in drop phase, 
    ; set the board bit as occupied    
    txa 
    cmp #%00110000
    bne +

    lda #%00010000
    bra @set_board_bits

+   txa
    cmp #%00001100
    bne + 

    lda #%00000100
    bra @set_board_bits

+   lda #%00000001

 @set_board_bits:
    sta BOARD_00, Y
    lda CURSOR__P1__x
    sta sprite__00__P1__x

    lda CURSOR__P1__y
    sta sprite__00__P1__y

    stz sprite__00__P1__counter
    stz sprite__00__P1__sprite

    ; current player is now 2
    inc current__PLAYER

    bra done_with_P1CONTROL
    ; get which "coin" this is (1, 2, 3) 
    ; (ie do we need to switch phase)   

    ; in move phase, 

    ; select piece that is going to be moved

    ; in move phase, 

    ; select new location for piece
    ;---------------------------


 done_with_P1CONTROL:

 check__P2__UP:
    lda joy2H__p
    and #%00001000
    beq check__P2__DOWN

    ;---------------------------
    lda CURSOR__P2__y
    cmp #$20
    beq check__P2__DOWN

    lda CURSOR__P2__y
    sec
    sbc #$40
    sta CURSOR__P2__y
    ;---------------------------

 check__P2__DOWN:
    lda joy2H__p
    and #%00000100
    beq check__P2__LEFT

    ;---------------------------
    lda CURSOR__P2__y
    cmp #$A0
    beq check__P2__LEFT

    lda CURSOR__P2__y
    clc
    adc #$40
    sta CURSOR__P2__y
    ;---------------------------

 check__P2__LEFT:
    lda joy2H__p
    and #%00000010
    beq check__P2__RIGHT

    ;---------------------------
    lda CURSOR__P2__x
    cmp #$50
    beq check__P2__RIGHT

    lda CURSOR__P2__x
    sec
    sbc #$40
    sta CURSOR__P2__x
    ;---------------------------

 check__P2__RIGHT:
    lda joy2H__p
    and #%00000001
    beq check__P2__A
    
    ;---------------------------
    lda CURSOR__P2__x
    cmp #$D0
    beq check__P2__A

    lda CURSOR__P2__x
    clc
    adc #$40
    sta CURSOR__P2__x
    ;---------------------------
    
 check__P2__A:
    lda joy2L__p
    and #%10000000
    beq done_with_P2CONTROL

    ; A PRESSED
    ;---------------------------
    ; current player is now 1
    stz current__PLAYER

    ldx #$00
    ldy #$00

    ; get the cursor x
    lda CURSOR__P2__x

    ;left 
    cmp #$50
    bne +

    ldx #%00110000

+   ;middle
    lda CURSOR__P2__x
    cmp #$90
    bne +

    ldx #%00001100

+   ;assume right
    ldx #%00000011

    ; get the cursor y
 A__check__P2__y:
    ; top
    lda CURSOR__P2__y
    cmp #$20
    bne +

    ldy #$00

+   ; middle 
    lda CURSOR__P2__y
    cmp #$60
    bne +

    ldy #$01

+   ; bottom 
    ldy #$02

    ; use x & y to determine where in the
    ; "board bits" it will go
    ; make sure it is not already taken 

    txa 
    and BOARD_00, Y

    ; if it is not ZERO we will get out
    ; cell is occupied
    ; PUT SOMETHING TO SHOW "BAD" FEEDBACK
    bne done_with_P2CONTROL 
    
    ; in drop phase, 
    ; set the board bit as occupied    
    txa 
    cmp #%00110000
    bne +

    lda #%00100000
    bra @set_board_bits

+   txa
    cmp #%00001100
    bne + 

    lda #%00001000
    bra @set_board_bits

+   lda #%00000010

 @set_board_bits:
    sta BOARD_00, Y
    lda CURSOR__P2__x
    sta sprite__00__P2__x

    lda CURSOR__P2__y
    sta sprite__00__P2__y

    stz sprite__00__P2__counter
    stz sprite__00__P2__sprite

    jmp forever

 done_with_P2CONTROL:
    ;---------------------------------
    ; --> drop phase
    ; ----> select the right pills
    
    ; ----> scroll pills 
    ; ----> start player 1
    
    ; ----> current player drops
    
    ; --------> selection sound as they move locations
    ; --------> make sure location is legal
    ; --------> change color/make a bad ding if they try to drop
    ; --------> nice ding / animation if it works
    ; --------> update connector graphics
     
    ; --------> check win conditions 
    ; (only do this at the very end)

    ; ----> switch to other player (back up to current player drops)

    ; --> move phase

    ; ----> current player moves

    ; --------> selection sound as they move locations
    ; --------> player selects one of their things
    ; --------> player selects legal location to move to
    ; --------> process move

    ; --------> check win conditions

    ; --------> switch players
    
    ; --> game over 
    ; ----> who won?
    ; ----> show that player won 

    ; --> reset stuff
    ; --> go back to title    
    ;----------------------------------------------------------
    
    jmp forever    ;<-- we outttttt t t t t t t t
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

    ;turn on screen
    ;(if not on)
    lda SCREEN__brightness
    cmp #$0F
    beq  +

    inc SCREEN__brightness
    lda SCREEN__brightness
    sta $2100
+
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
InitHDMA:
    lda #$02 ; mode 2 = 2 bytes per scanline
    sta $4310 ; DMAP1


    lda #$0D ; $210D = BG1 HOFS
    sta $4311 ; BBAD1


    lda #<HDMA_table
    sta $4312 ; table low
    lda #>HDMA_table
    sta $4313 ; table high


    lda #:HDMA_table
    sta $4314 ; table bank

    rts
;---------------------------------------------------------------

;---------------------------------------------------------------
MAKE__HDMAtable:
    lda #32
    sta HDMA_table

    stz HDMA_table + 1
    stz HDMA_table + 2

    lda #192
    sta HDMA_table + 3

    stz HDMA_table + 4
    stz HDMA_table + 5

    stz HDMA_table + 6
    rts
;---------------------------------------------------------------


;---------------------------------------------------------------
draw__COIN:
    ;set x position
    ldx COIN__cell__index    
    lda.l COIN_X_values, X
    ldx COIN__sOAMoffset
    sta $0000, X
    inc COIN__sOAMoffset

    ;set y position
    ldx COIN__cell__index    
    lda.l COIN_Y_values, X
    ldx COIN__sOAMoffset
    sta $0000, X
    inc COIN__sOAMoffset

    ;set tile
    ldx COIN__cell__index   
    lda COIN__X_or_O, X
    beq +
    
    sep #$10
    ldx COIN__cell__index    
    lda COIN__anim__spriteINDEX, X
    tax 
    lda.l sprite__O__indices, X
    ldx COIN__sOAMoffset
    sta $0000, X
    rep #$10    
    bra @inc__sOAMoffset
+
    sep #$10
    ldx COIN__cell__index    
    lda COIN__anim__spriteINDEX, X
    tax 
    lda.l sprite__X__indices, X
    ldx COIN__sOAMoffset
    sta $0000, X
    rep #$10    

@inc__sOAMoffset:
    inc COIN__sOAMoffset

    ;other props
    ldx COIN__cell__index   
    lda COIN__X_or_O, X
    beq +

    ;coin is O (value is 1)
    lda #%00100000
    ldx COIN__sOAMoffset
    sta $0000, X

    lda #$0D
    ldx COIN__cell__index
    sta COIN__anim__finalFRAME, X
    bra @sOAM__lastVALUE
+
    ;coin is X (value is 0)
    lda #%00100001
    ldx COIN__sOAMoffset
    sta $0000, X

    lda #$0B
    ldx COIN__cell__index
    sta COIN__anim__finalFRAME, X

@sOAM__lastVALUE:

    inc COIN__sOAMoffset

    ;process waiting/counters
    ldx COIN__cell__index
    lda COIN__anim__spriteINDEX, X
    cmp COIN__anim__finalFRAME, X
    bne + 
    
    rts
+
    lda COIN__anim__counters, X
    cmp sprite__wait
    bne +

    lda #$00
    sta COIN__anim__counters, X
    inc COIN__anim__spriteINDEX, X

+   inc COIN__anim__counters, X
    rts
;---------------------------------------------------------------

; (END of SUBROUTINES)

; DATA TABLESf
;---------------------------------------------------------------
CURSOR__tile:
    .db $C8, $CC

COIN_X_values:
    .db $50, $90, $D0, $50, $90, $D0, $50, $90, $D0

COIN_Y_values:
    .db $20, $20, $20, $60, $60, $60, $A0, $A0, $A0 

sprite__O__indices:
    .db $00, $04, $08, $0C, $40, $44, $48, $4C, $80, $84, $88, $8C, $C0, $C4

 sprite__X__indices:
    .db $00, $04, $08, $0C, $40, $44, $48, $4C, $80, $84, $88, $8C
;---------------------------------------------------------------
.ENDS

; graphics
;---------------------------------------------------------------
.BANK 1 SLOT 0
.ORG 0
.SECTION "graphic_and_audio__includes"

; all the tiles for the game board
 bg__palette:
    .incbin "_graphics/TAPATAN__bg.clr"
 bg__tiles:
    .incbin "_graphics/TAPATAN__bg.pic"

; tiles for "coin" sprites, and cursor
 sprites__palette: 
    .incbin "_graphics/TAPATAN__sprites__v02.clr"
 sprites__tiles: 
    .incbin "_graphics/TAPATAN__sprites__v02.pic"

; sound stuff
 spc_program:
    .incbin "spc__playWithCollide.bin"
    .incbin "audio/guitar_palmmuted__C__32k.BRR"
 spcend:
        .db $FF

 rando_map:
    .incbin "random_tilemap.bin"

 tilemap__BG01:
    .dw $4006, $0008, $0004, $4004, $4008, $8004, $C002, $4004, $0006, $0004, $0006, $0006, $8004, $8006, $8006, $8002, $8002, $C002, $0002, $0004, $8008, $0008, $0002, $4008, $4008, $4006, $8006, $C006, $8008, $0002, $4008, $0002        
    .dw $4004, $4006, $4004, $C006, $4004, $8004, $4006, $0006, $8004, $4008, $0002, $8004, $8004, $4006, $8004, $4004, $4008, $8008, $8006, $C002, $4006, $8002, $0006, $C004, $4008, $8004, $8008, $C006, $4006, $8008, $C008, $0002        
    .dw $C004, $C004, $0002, $C004, $4006, $000A, $400A, $0024, $0024, $000A, $400A, $0024, $0024, $000A, $400A, $8008, $C006, $4008, $0002, $4006, $C008, $C002, $C006, $4004, $0002, $8004, $8008, $C004, $0008, $4004, $0008, $0008        
    .dw $8004, $C004, $0002, $8006, $8004, $0022, $4020, $402C, $0002, $0022, $4022, $4004, $002C, $0020, $4022, $8004, $4002, $C006, $8002, $C004, $0004, $8004, $8004, $C004, $4002, $0008, $C006, $0006, $0002, $C004, $C006, $8008        
    .dw $4004, $8006, $8006, $C002, $0002, $4028, $0026, $402A, $402C, $4028, $0028, $002C, $002A, $4026, $0028, $C006, $C004, $0002, $8004, $8006, $8002, $4002, $4002, $0008, $8002, $8008, $C006, $0006, $C008, $0004, $4002, $0006        
    .dw $8008, $0006, $C002, $0006, $8008, $4028, $0028, $802C, $402A, $C026, $8026, $002A, $C02C, $4028, $0028, $C002, $C006, $0008, $0008, $8006, $8002, $0002, $C004, $8008, $8002, $4006, $0008, $C006, $C002, $4008, $C008, $8002        
    .dw $C002, $C002, $4008, $0004, $8004, $000C, $400C, $0024, $402E, $000E, $400E, $002E, $0024, $000C, $400C, $8008, $C008, $4006, $0002, $8006, $C006, $4006, $0002, $4004, $4006, $C008, $4008, $8002, $C004, $4004, $C008, $C006        
    .dw $C008, $4004, $C004, $C006, $4008, $0022, $4022, $4002, $002C, $0020, $4020, $402C, $0006, $0022, $4022, $0004, $4006, $0006, $8008, $C006, $8004, $8002, $C002, $C004, $4006, $4008, $0004, $8006, $8002, $0002, $8006, $0006        
    .dw $4006, $8004, $0004, $C004, $4002, $4028, $0028, $002C, $002A, $4026, $0026, $402A, $402C, $4028, $0028, $4008, $8006, $0004, $8002, $0002, $C004, $8008, $C002, $4008, $0006, $8006, $4008, $4008, $8004, $0008, $C002, $8004        
    .dw $8008, $8002, $C008, $8002, $8004, $4028, $8026, $002A, $C02C, $4028, $0028, $802C, $402A, $C026, $0028, $0008, $8008, $4006, $4006, $4002, $0004, $4006, $C002, $4006, $4006, $8004, $0004, $4008, $0002, $8004, $0004, $C008        
    .dw $0002, $0002, $8008, $4002, $0006, $000C, $400E, $002E, $0024, $000C, $400C, $0024, $402E, $000E, $400C, $8006, $0002, $4008, $4004, $8008, $4002, $4008, $8004, $C008, $8006, $8002, $8006, $C008, $C004, $0008, $8004, $0008        
    .dw $0006, $0006, $C004, $8002, $8002, $0022, $4022, $C004, $C008, $0022, $4022, $0006, $C006, $0022, $4022, $C008, $8004, $C008, $8008, $0006, $4008, $C004, $8004, $4002, $C004, $4004, $4008, $0002, $4004, $4004, $C008, $4006        
    .dw $4002, $8004, $4004, $8004, $C002, $0006, $8008, $8008, $C002, $4002, $C006, $0004, $0002, $4006, $C004, $C004, $C002, $4006, $8004, $4004, $0004, $8006, $0004, $4004, $8008, $0004, $0006, $4004, $4006, $4006, $C004, $0002        
    .dw $0002, $C004, $0002, $C008, $4006, $C006, $8004, $4002, $8008, $C006, $8006, $8004, $4004, $C006, $C002, $C004, $0002, $C004, $4008, $C006, $0004, $8004, $0008, $0002, $4008, $C008, $0008, $0006, $0006, $C008, $0004, $0002        
    .dw $8006, $0002, $C008, $4004, $8004, $C006, $8006, $0006, $0006, $0006, $C008, $4004, $4004, $0008, $8002, $4008, $8002, $4002, $8008, $8004, $8004, $0004, $C002, $0006, $4004, $8008, $C002, $8006, $C008, $C002, $0004, $4006      
    .dw $4006, $0008, $0004, $4004, $4008, $8004, $C002, $4004, $0006, $0004, $0006, $0006, $8004, $8006, $8006, $8002, $8002, $C002, $0002, $0004, $8008, $0008, $0002, $4008, $4008, $4006, $8006, $C006, $8008, $0002, $4008, $0002        

 tilemap__BG02__drop:
    .dw $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000 
    .dw $0040, $0042, $0044, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000
    .dw $0048, $004A, $004A, $4048, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000 
    .dw $4060, $0088, $4064, $0060, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000
    .dw $4060, $006C, $008A, $0060, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000 
    .dw $4060, $0064, $4064, $0060, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000
    .dw $4060, $006C, $006E, $0060, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000 
    .dw $4060, $0002, $4004, $0060, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000
    .dw $4060, $006C, $006E, $0060, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000 
    .dw $4060, $0080, $4080, $0060, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000
    .dw $4060, $0082, $4082, $0060, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000 
    .dw $4060, $0084, $0086, $0060, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000
    .dw $4060, $0068, $006A, $0060, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000 
    .dw $004C, $004E, $004E, $404C, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000
    .dw $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000 

 tilemap__BG02__move:
    .dw $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000 
    .dw $0040, $0042, $0046, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000
    .dw $0048, $004A, $004A, $4048, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000 
    .dw $4060, $0062, $4062, $0060, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000
    .dw $4060, $0064, $4064, $0060, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000 
    .dw $4060, $0066, $4066, $0060, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000
    .dw $4060, $0068, $006A, $0060, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000 
    .dw $4060, $0002, $4004, $0060, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000
    .dw $4060, $006C, $006E, $0060, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000 
    .dw $4060, $0080, $4080, $0060, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000
    .dw $4060, $0082, $4082, $0060, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000 
    .dw $4060, $0084, $0086, $0060, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000
    .dw $4060, $0068, $006A, $0060, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000 
    .dw $004C, $004E, $004E, $404C, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000
    .dw $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000 

;---------------------------------------------------------------
.ENDS
