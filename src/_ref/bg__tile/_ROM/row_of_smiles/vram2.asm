;includes
;-----------------------------------------------------------------
.INCLUDE "header.inc"
.INCLUDE "InitSNES.asm"
.INCLUDE "LoadGraphics.asm"

;main stuff
;------------------------------------------------------------------
.BANK 0 SLOT 0
.ORG 0
.SECTION "MainCode"

Start:
    InitSNES    ; Clear registers, etc.

    ; Load Palette for our tiles
    LoadPalette BG_Palette, 0, 16

    ; Load Tile data to VRAM
    LoadBlockToVRAM Tiles, $0000, $0020	; 2 tiles, 2bpp, = 32 bytes

    lda #%00000000     ;%00000000
    sta $2115
    ldx #$0400	; 5AF
    stx $2116

    ;display 32 smiles
    ;or one row
    ldx #$1f
smiley_loop:  
    
    ;display smiley tile
    lda #$01
    sta $2118

    dex
    lda 0,x
    cmp #%00000000
    bpl smiley_loop

    ; Setup Video modes and other stuff, then turn on the screen
    jsr SetupVideo

Infinity:
    jmp Infinity    ; bwa hahahahaha



; SetupVideo -- Sets up the video mode and tile-related registers
;----------------------------------------------------------------------------
; In: None
;----------------------------------------------------------------------------
; Out: None
;----------------------------------------------------------------------------
SetupVideo:
    php

    lda #$00
    sta $2105           ; Set Video mode 0, 8x8 tiles, 4 color BG1/BG2/BG3/BG4

    lda #$04            ; Set BG1's Tile Map offset to $0400 (Word address)
    sta $2107           ; And the Tile Map size to 32x32

    stz $210B           ; Set BG1's Character VRAM offset to $0000 (word address)

    lda #$01            ; Enable BG1
    sta $212C

    lda #$FF
    sta $210E
    sta $210E

    lda #$0F
    sta $2100           ; Turn on screen, full Brightness

    plp
    rts
.ENDS

;tile and palette
;------------------------------------------------------------------
.BANK 1 SLOT 0
.ORG 0
.SECTION "CharacterData"

    .INCLUDE "tiles.inc"
.ENDS