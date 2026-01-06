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

    ;load palette for sprites
    LoadPalette meteor__01__palette, 128, 16

    ;load tiles to VRAM
    LoadBlockToVRAM meteor__01__image, $4000, $400

    ;initialize sprites
    ;---------------------------------------------
    ;put RAM "copy" of sprites offscreen
    jsr SpriteInit    

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
    ;enable 9th x-bits
    lda #%00000000
    sta $0200
    lda #%00000000
    sta $0201
    
    ; Setup Video modes and other stuff, then turn on the screen
    jsr SetupVideo
    
    lda #$80
    sta $4200 ;Enable NMI

    lda #%01100010      ;8x8 and 16x16 sprites (obj size #0)
    sta $2101

    lda #%00010001      ;Enable BG1
    sta $212C
    
    lda #$0F
    sta $2100           ;Turn on screen, full Brightness


;loop
;------------------------------------------
forever:
    wai

    clc 
    lda $0001
    adc #$02
    sta $0001

    clc 
    lda $0005
    adc #$02
    sta $0005

    clc 
    lda $0009
    adc #$02
    sta $0009

    clc 
    lda $000D
    adc #$02
    sta $000D

    clc 
    lda $0011
    adc #$02
    sta $0011

    clc 
    lda $0015
    adc #$02
    sta $0015

    clc 
    lda $0019
    adc #$02
    sta $0019

    clc 
    lda $001D
    adc #$02
    sta $001D

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

	PLY 
	PLX 
	PLA 

    RTI
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

.ENDS

;------------------------------------------