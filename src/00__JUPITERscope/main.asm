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
.INCLUDE "inc/load_graphics.asm"

; REGISTERS
;------------------------------------------
; https://snes.nesdev.org/wiki/PPU_registers

; CGRAM is "color graphics ram" 
; where the palette data lives

; $2100 --> INIDISP -->  FXXX BBBB --> force blanking (f), and screen brightness (b)
; $2121 --> CGADD   --> which color to write
; $2122 --> CGDATA  --> the color to write

; $210B --> BG12NBA
; $2115 --> VMAIN
; $2116 --> VADDRL
; $2105 --> BGMODE
; $212C --> TM 
; $4200 --> NMITIMEN

;   controller registers
;   JOY1H       JOY1L
;   $4219       $4218
;15  bit  8   7  bit  0
; ---- ----   ---- ----
; BYsS UDLR   AXlr 0000
; |||| ||||   |||| ||||
; |||| ||||   |||| ++++- Signature
; |||| ||||   ||++------ L/R shoulder buttons
; |||| ||||   ++-------- A/X buttons
; |||| ++++------------- D-pad
; ||++------------------ Select (s) and Start (S)
; ++-------------------- B/Y buttons
;------------------------------------------

; VARIABLES 
;------------------------------------------
; $0000 - $0220 --> "shadow" of OAM
.EQU joy1H__c $0221
.EQU joy1H__p $0222
.EQU joy1H__h $0223

.EQU ship__speed    $0224
.EQU meteor__speed  $0225
.EQU bullet__speed  $0226
.EQU bullet__firing $0227

;wait counter for new meteors
.EQU meteor__count  $0229
.EQU meteor__moving $0230
.EQU wait__c        $0228

.EQU sploder_x      $023A
.EQU sploder_y      $023B
.EQU sploder_timer  $023C
.EQU sploder_timer_on $023D

.EQU rng            $023E

;------------------------------------------

;where to put this section of code
;------------------------------------------
.BANK   0   SLOT 0
.ORG    0
.SECTION "MainCode"

;------------------------------------------
Start:
    ; START UP THE SNES 
    InitSNES            

    ; initialize variables
    ;--------------------------------
    lda #$04
    sta ship__speed

    lda #$01
    sta meteor__speed

    lda #$08
    sta bullet__speed

    stz bullet__firing
    stz wait__c
    stz meteor__count
    stz meteor__moving
    stz sploder_x
    stz sploder_y
    stz sploder_timer
    stz sploder_timer_on
    stz rng
    ;--------------------------------

    ; Load Palette to VRAM
    ;--------------------------------
    ;4bits per pixel so 16 palette entries
    LoadPalette JUPITERscope__bg01__palette, 0, 16

    stz $210B
    
    ;to determine size (3rd parameter)
    ;you must, do this
    ;8 * bits per pixel * number of characters so we have
    ;8 * 4 * 896 = 28672 = 0x7000

    LoadBlockToVRAM JUPITERscope__bg01__image, $0000, $7000	

    ; Load tile map data to VRAM
    ; ---------------------------------
    ; we are trying to store an image which is essentially
    ; just a bunch of tiles in a consecutive sequence.

    ; set to increment when writing to $2118
    lda #%10000000     
    sta $2115

    lda #$70            ; Set BG1's Tile Map offset
    sta $2107           ; And the Tile Map size to 32x32

    ; set the starting address for the tilemap
    ; (it must be at $7000 because that is the end 
    ; of where we are storing the character data)
    ldx #$7000
    stx $2116

    ;get x and y ready
    ldx #$0000

    ; just increment 
    ; no actual map
loop_for_bg:
    stx $2118   ;put tile number into VRAM low
    inx
    cpx #$0E00
    bne loop_for_bg

    ;we have a 4bpp graphic (16 palette entries)
    ;so we want to use background mode 1
    ;which has that option for bg 1
    lda #%00001001        
    sta $2105    

    ; sprite stuff
    ; ------------------------------------------------

    ;load palettes + graphics for sprites
    LoadPalette meteor__01__palette, 128, 16
    LoadBlockToVRAM meteor__01__image, $4000, $400
    LoadPalette ship__palette, 144, 16
    LoadBlockToVRAM ship__palette, $4200, $800    
    LoadPalette fireball__palette, 160, 16
    LoadBlockToVRAM fireball__palette, $4600, $400
    LoadPalette sploder__palette, 176, 16
    LoadBlockToVRAM sploder__image, $4800, $800

    ;initialize sprites
    ;---------------------------------------------
    ;put RAM "copy" of sprites offscreen
    jsr SpriteInit    

    ; SPRITES THAT COMPOSE THE METEOR
    ; just do 32x32? 
    ; re-export the images
    ; loop through this better regardless
    ;----------------------
    ;initialize sprite properties
    ;center sprite 
    ;set x (screen *.5 / width of sprite)
    lda #(256/2 - 16)
    sta $0000
    
    ;set y (screen.height * .5/height of sprite)
    lda #(-32)
    sta $0001
    
    ;first tile
    lda #$00
    sta $0002
    
    lda #%00110000
    sta $0003
    ;----------------------------
    
    ;----------------------
    ;initialize sprite properties
    ;center sprite 
    ;set x (screen *.5 / width of sprite)
    lda #(256/2)
    sta $0004
    
    ;set y (screen.height * .5/height of sprite)
    lda #(-32)
    sta $0005
    
    ;first tile
    lda #$02
    sta $0006
    
    lda #%00110000
    sta $0007
    ;----------------------------

    ;----------------------
    ;initialize sprite properties
    ;center sprite 
    ;set x (screen *.5 / width of sprite)
    lda #(256/2 - 16)
    sta $0008
    
    ;set y (screen.height * .5/height of sprite)
    lda #(-16)
    sta $0009
    
    ;first tile
    lda #$04
    sta $000A
    
    lda #%00110000
    sta $000B
    ;----------------------------

    ;----------------------
    ;initialize sprite properties
    ;center sprite 
    ;set x (screen *.5 / width of sprite)
    lda #(256/2)
    sta $000C
    
    ;set y (screen.height * .5/height of sprite)
    lda #(-16)
    sta $000D
    
    ;first tile
    lda #$06
    sta $000E
    
    lda #%00110000
    sta $000F
    ;----------------------------

    ;----------------------
    ;initialize sprite properties
    ;center sprite 
    ;set x (screen *.5 / width of sprite)
    lda #(256/2 - 16)
    sta $0010
    
    ;set y (screen.height * .5/height of sprite)
    lda #(00)
    sta $0011
    
    ;first tile
    lda #$08
    sta $0012
    
    lda #%00110000
    sta $0013
    ;----------------------------

    ;----------------------
    ;initialize sprite properties
    ;center sprite 
    ;set x (screen *.5 / width of sprite)
    lda #(256/2)
    sta $0014
    
    ;set y (screen.height * .5/height of sprite)
    lda #(00)
    sta $0015
    
    ;first tile
    lda #$0A
    sta $0016
    
    lda #%00110000
    sta $0017
    ;----------------------------

    ;----------------------
    ;initialize sprite properties
    ;center sprite 
    ;set x (screen *.5 / width of sprite)
    lda #(256/2 - 16)
    sta $0018
    
    ;set y (screen.height * .5/height of sprite)
    lda #$10
    sta $0019
    
    ;first tile
    lda #$0C
    sta $001A
    
    lda #%00110000
    sta $001B
    ;----------------------------

    ;----------------------
    ;initialize sprite properties
    ;center sprite 
    ;set x (screen *.5 / width of sprite)
    lda #(256/2)
    sta $001C
    
    ;set y (screen.height * .5/height of sprite)
    lda #$10
    sta $001D
    
    ;first tile
    lda #$0E
    sta $001E
    
    lda #%00110000
    sta $001F
    ;----------------------------        

    ;SHIP
    ;----------------------------        
    lda #(256/2 - 16)
    sta $0020

    lda #(180)
    sta $0021

    lda #$21
    sta $0022

    lda #%00110010
    sta $0023
    ;----------------------------        

    ; BULLET(s)
    ;----------------------------        
    ; ship x + 8
    lda $0020
    clc 
    adc #$08
    sta $0024

    ;same as ship starting y
    lda $0021
    sta $0025

    lda #$61
    sta $0026

    lda #%00100100
    sta $0027
    ;----------------------------        

    ;enable 9th x-bits
    lda #%00000000
    sta $0200
    lda #%00000000
    sta $0201
    lda #%01110110
    sta $0202

    lda #$81
    sta $4200               ;Enable NMI + enable joy pad

    lda #%01100010          ;16x16 and 32x32 sprites 
    sta $2101

    ; Setup Video modes and other stuff, then turn on the screen
    jsr SetupVideo

    lda #%00010001      ;Enable BG1
    sta $212C
    
    lda #$0F
    sta $2100           ;Turn on screen, full Brightness

    ;initialize randomness
    lda $4210
    sta rng

;loop
;------------------------------------------
forever:
    wai

    ;refresh the rng
    ;-----------------------------------------
    lda rng
    asl 
    bcc +
    eor #$1D
+
    sta rng
    ;-----------------------------------------
    ;check if there is a sploder timer
    lda sploder_timer_on
    cmp #$01
    bne meteor__canMOVE

    ; incrememt if it is on
    inc sploder_timer

    ; check if it is at it's max
    lda sploder_timer
    cmp #$04
    bne meteor__canMOVE

    ; if it is, turn the sprite back on
    lda $0202
    eor #%00010000
    sta $0202

    ; and reset timer and flag
    stz sploder_timer
    stz sploder_timer_on

    ;check if the meteor can move
meteor__canMOVE:
    lda wait__c
    cmp #$10
    bne +

    ;meteor is ready to move
    ;show the front half
    stz $0201

    lda #$01
    sta meteor__moving

    bra move__meteor
+   
    inc wait__c
    jmp move__bullet

move__meteor:
    lda meteor__moving
    cmp #$01
    beq + 

    jmp move__bullet

+
    ; we can do two values at a time
    ; because there are two 16x16 sprites
    ; per line (with the same y value)
    lda $0001    
    clc 
    adc meteor__speed
    sta $0001
    sta $0005

    lda $0009
    clc 
    adc meteor__speed
    sta $0009
    sta $000D
      
    lda $0011
    clc 
    adc meteor__speed
    sta $0011
    sta $0015
    
    lda $0019
    clc 
    adc meteor__speed
    sta $0019
    sta $001D
    
    ;check bottom-most sprite is on scree right quick
    lda $0019
    cmp #$10
    bcc + 

    lda $0019
    cmp #$EF
    bcs +

    stz $0200
+
    ;-------------------

    ; move bullets
    ;-------------------
move__bullet:
    lda bullet__firing
    cmp #$01
    beq +

    jmp _left_check

    ; move the bullet up
+   lda $0025
    sec
    sbc bullet__speed
    sta $0025

    ; check if it is offscreen
    lda $0025
    clc 
    adc #$10
    cmp #$F0
    bcs +

    bra _check_y__1

+   jmp _reset_bullet

    ; check collisions between bullet and meteor 
    ; check onscreen
_check_onscreen:
    lda $0200
    cmp #%00000000
    beq _check_y__1

    jmp _left_check

    ; if bullet y <= meteor bottom sprite y 
_check_y__1:
    lda $0025
    sec
    sbc #$10
    cmp $0019
    bcc _check_x__1

    jmp _left_check

    ; if bullex x + width >= meteor x
_check_x__1:
    lda $0024
    clc
    adc #$10
    cmp $0018
    bcs _check_x__2

    jmp _left_check

    ; if bullet x <= meteor x + width
_check_x__2:
    lda $0018
    clc
    adc #$20
    cmp $0024
    bcs _show_sploder
    ;-------------------
    jmp _left_check

_show_sploder:
    lda $0024
    sec 
    sbc #$08
    sta sploder_x
    sta $0028

    lda $0025
    sta sploder_y
    sta $0029

    lda #$80
    sta $002A

    lda #%00100110
    sta $002B

    lda $0202
    and #%11101111
    sta $0202

    lda #$01
    sta sploder_timer_on

_reset_meteor:
    ; deal with the counter & speed

    ;compare to max speed
    lda meteor__speed
    cmp #$10
    beq meteor_moving_counter_reset

    lda meteor__count
    cmp #$08
    bcc + 

    stz meteor__count 
    inc meteor__speed
    bra meteor_moving_counter_reset

+
    inc meteor__count

meteor_moving_counter_reset:
    ; reset wait counter & flag
    stz wait__c
    stz meteor__moving

    ; put meteor off screen
    lda #%01010101
    sta $0200
    sta $0201
        
    ; SPRITES THAT COMPOSE THE METEOR
    ; just do 32x32? 
    ; re-export the images
    ; loop through this better regardless
    ;------------------------------------------------------
    ;------------------------------------------------------
    ;initialize sprite properties
    ;center sprite 
    ;set x (screen *.5 / width of sprite)
    lda rng
    and #$DF
    sta $0000
    
    ;set y (screen.height * .5/height of sprite)
    lda #(-64)
    sta $0001
    
    ;first tile
    lda #$00
    sta $0002
    
    lda #%00110000
    sta $0003
    ;----------------------------
    
    ;----------------------
    ;initialize sprite properties
    ;center sprite 
    ;set x (screen *.5 / width of sprite)
    lda rng
    and #$DF
    clc
    adc #$10
    sta $0004
    
    ;set y (screen.height * .5/height of sprite)
    lda #(-64)
    sta $0005
    
    ;first tile
    lda #$02
    sta $0006
    
    lda #%00110000
    sta $0007
    ;----------------------------

    ;----------------------
    ;initialize sprite properties
    ;center sprite 
    ;set x (screen *.5 / width of sprite)
    lda rng
    and #$DF
    sta $0008
    
    ;set y (screen.height * .5/height of sprite)
    lda #(-48)
    sta $0009
    
    ;first tile
    lda #$04
    sta $000A
    
    lda #%00110000
    sta $000B
    ;----------------------------

    ;----------------------
    ;initialize sprite properties
    ;center sprite 
    ;set x (screen *.5 / width of sprite)
    lda rng
    and #$DF
    clc
    adc #$10
    sta $000C
    
    ;set y (screen.height * .5/height of sprite)
    lda #(-48)
    sta $000D
    
    ;first tile
    lda #$06
    sta $000E
    
    lda #%00110000
    sta $000F
    ;----------------------------

    ;----------------------
    ;initialize sprite properties
    ;center sprite 
    ;set x (screen *.5 / width of sprite)
    lda rng
    and #$DF
    sta $0010
    
    ;set y (screen.height * .5/height of sprite)
    lda #(-32)
    sta $0011
    
    ;first tile
    lda #$08
    sta $0012
    
    lda #%00110000
    sta $0013
    ;----------------------------

    ;----------------------
    ;initialize sprite properties
    ;center sprite 
    ;set x (screen *.5 / width of sprite)
    lda rng
    and #$DF
    clc
    adc #$10
    sta $0014
    
    ;set y (screen.height * .5/height of sprite)
    lda #(-32)
    sta $0015
    
    ;first tile
    lda #$0A
    sta $0016
    
    lda #%00110000
    sta $0017
    ;----------------------------

    ;----------------------
    ;initialize sprite properties
    ;center sprite 
    ;set x (screen *.5 / width of sprite)
    lda rng 
    and #$DF   
    sta $0018
    
    ;set y (screen.height * .5/height of sprite)
    lda #(-16)
    sta $0019
    
    ;first tile
    lda #$0C
    sta $001A
    
    lda #%00110000
    sta $001B
    ;----------------------------

    ;----------------------
    ;initialize sprite properties
    ;center sprite 
    ;set x (screen *.5 / width of sprite)
    lda rng
    and #$DF
    clc
    adc #$10
    sta $001C
    
    ;set y (screen.height * .5/height of sprite)
    lda #(-16)
    sta $001D
    
    ;first tile
    lda #$0E
    sta $001E
    
    lda #%00110000
    sta $001F
    ;------------------------------------------------------
    ;------------------------------------------------------

    ;reset if bullet is ready to reset
_reset_bullet:
    stz bullet__firing
    lda #%00000100
    ora $0202
    sta $0202   ;set off screen
    lda $0021
    sta $0025
    
    ; check collisions between meteors and ship
_check_collisions_ship_and_meteors:
    ; check meteor is on screen 
    lda $0200
    cmp #%00000000
    beq _check_SHIP_y__1

    bra left_check

_check_SHIP_y__1:
    ;check meteor_y (lowest sprite) + height >= ship_y
    lda $0019
    clc 
    adc #$20
    cmp $0021
    bcs _check_SHIP_x__1

    jmp _left_check

_check_SHIP_x__1:
    ;check ship x + width > meteor X
    lda $0021
    clc 
    adc #$20
    cmp $0018
    bcs _check_SHIP_X__2

    jmp _left_check

_check_SHIP_X__2:
    ;check meteor x + width < ship X
    lda $0018
    clc 
    adc #$20
    cmp $0018
    bcc _handle_SHIP_collision

    jmp _left_check

_handle_SHIP_collison:
    ;show sploder
    
    ;reset meteor

    ;reset ship

;check directional controls
;---------------------------------------------
_left_check:
    lda joy1H__h
    and #%00000010
    bne +

    bra _right_check
+
    lda $0020
    sec
    sbc ship__speed
    sta $0020

    ;if carry is clear set 
    ;x explicitly to zero
    bcc +

    bra _right_check

+   stz $0020

_right_check:
    lda joy1H__h
    and #%00000001
    bne +

    bra _Y_check
+
    lda $0020
    clc
    adc ship__speed
    sta $0020

    cmp #$E0    
    bcs +

    bra _Y_check

+   lda #$E0
    sta $0020  

_Y_check:
    lda joy1H__h
    and #%01000000
    bne +
    
    jmp forever
+
    lda bullet__firing
    cmp #$00
    beq +

    jmp forever
+
    ; set bit for bullet to be on screen
    lda $0202
    and #%11111011  ;explicitly set to on screen
    sta $0202

    ; set bullet x to be ship x + 8
    lda $0020
    clc 
    adc #$08
    sta $0024

    lda #$01
    sta bullet__firing 

    jmp forever


;S U B R O U T I N E S

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


;NMI (vblank) code
;---------------------------------------------------------------
VBlank:
	pha
	phx
	phy
    ;-----------------

    rep #$10    
    sep #$20
    
    ; "shadow OAM --> actual OAM"
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

    ;get joypad status 
- 
    lda $4212
    and #$01
    bne - 

    ;read controler 1 high
    ; DO I NEED TO COPY THIS?
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

    ;-----------------
    ply
    plx 
    pla 
	
    rti
.ENDS

; DATA
;------------------------------------------
.BANK 1 SLOT 0
.ORG 0 
.SECTION "CharacterData"
    JUPITERscope__bg01__palette:
        .incbin "_graphics/JUPITERscope__bg01.clr"

    JUPITERscope__bg01__image:
        .incbin "_graphics/JUPITERscope__bg01.pic"

    meteor__01__palette:
        .incbin "_graphics/meteor__01.clr"

    meteor__01__image:
        .incbin "_graphics/meteor__01.pic"

    ship__palette: 
        .incbin "_graphics/ship__v01.clr"
    
    ship__image:
        .incbin "_graphics/ship__v01.pic"
.ENDS

.BANK 2 SLOT 0
.ORG 0 
.SECTION "MORECharacterData"
    fireball__palette: 
        .incbin "_graphics/fireball__v01.clr"

    fireball__image:
        .incbin "_graphics/fireball__v01.pic"
    sploder__palette:
        .incbin "_graphics/sploder.clr"        
    sploder__image:
        .incbin "_graphics/sploder.pic"
.ENDS
;------------------------------------------