;includes
;-----------------------------------------------------------------
.INCLUDE "inc/header.inc"   ;<-- header for this ROM, must be first

;universal includes
.INCLUDE "../../__inc/registers.inc"
.INCLUDE "../../__inc/init_snes.inc"

;more includes just for this ROM
.INCLUDE "inc/LoadGraphics.asm"

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

    lda #%00000000     
    sta V_main

    ldx #$0400	
    stx V_Addr_L

    ;display screens-worth of tiles
    ldx #$400
smiley_loop:  
    
    ;display smiley tile one-th tile of the ones we have
    lda #$01
    sta V_Data_L

    dex
    lda 0,x
    cmp #%00000000
    bpl smiley_loop

    ; Setup Video modes and other stuff, then turn on the screen
    jsr SetupVideo
    lda #%10000000
    sta NMI_inimen       ;<--"Counter Enable" register this bit pattern enables NMI

;main loop
;-------------------------------------------------------
Infinity:

lda #$00
scroll_test_d:     
    sta BG_1_hofs
    sta BG_1_vofs
    WAI  
    
    ina
    cmp #$80
    bne scroll_test_d

lda #$00
scroll_test_h:     
    sta BG_1_hofs
    WAI  
    
    ina
    cmp #$80
    bne scroll_test_h

lda #$00
scroll_test_v:     
    sta BG_1_vofs
    WAI  
    
    ina
    cmp #$80
    bne scroll_test_v

    jmp Infinity   
;-------------------------------------------------------

.INCLUDE "inc/setup_video.inc"

.ENDS

;tile and palette
;------------------------------------------------------------------
.BANK 1 SLOT 0
.ORG 0
.SECTION "CharacterData"
    .INCLUDE "graphics/tiles.inc"
.ENDS