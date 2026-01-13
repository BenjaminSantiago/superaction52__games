;includes
;-----------------------------------------------------------------
.INCLUDE "inc/header.inc"   ;<-- header for this ROM, must be first

;universal includes
.INCLUDE "../__inc/registers.inc"
.INCLUDE "../__inc/init_snes.inc"

.INCLUDE "inc/LoadGraphics.asm"


;main stuff
;------------------------------------------------------------------
.BANK 0 SLOT 0
.ORG 0
.SECTION "MainCode"

Start:
    InitSNES    ; Clear registers, etc.

    ; Load Palette to VRAM
    ;--------------------------------
    ;4bits per pixel so 16 palette entries

    LoadPalette blue_palette_16, 0, 16

    ; Load Tile data to VRAM
    ;---------------------------------
    stz $210B           ; Set BG1's Character VRAM offset to $0000 (word address)

    ;to determine size (3rd parameter)
    ;you must, do this
    ;8 * bits per pixel * number of characters so we have
    ;8 * 4 * 896 = 28672 = 0x7000

    LoadBlockToVRAM blue_head, $0000, $7000	

    ; Load tile map data to VRAM
    ; ---------------------------------
    ; we are trying to store an image which is essentially
    ; just a bunch of tiles in a consecutive sequence.

    ; set to increment when writing to $2118
    lda #%10000000     
    sta V_main

    lda #$70            ; Set BG1's Tile Map offset
    sta $2107           ; And the Tile Map size to 32x32

    ; set the starting address for the tilemap
    ; (it must be at $7000 because that is the end 
    ; of where we are storing the character data)
    ldx #$7000
    stx V_Addr_L

    ;get x and y ready
    ldx #$0000

;--------------------------------------------------------
blue_head_loop:      
    stx V_Data_L    ;put tile number into VRAM Low.
             
    inx
    cpx #$0E00             
    bne blue_head_loop
;--------------------------------------------------------

    ;we have a 4bpp graphic (16 palette entries)
    ;so we want to use background mode 1
    ;which has that option for bg 1
    lda #%00000001        
    sta $2105    

    lda #$01            ; Enable BG1
    sta $212C

    lda #$0F
    sta $2100           ; Turn on screen, full Brightness

    lda #%10000000
    sta NMI_inimen       ;<--"Counter Enable" register this bit pattern enables NMI

    ;set the horizontal counter
    lda #$01
    lda $4207

;main loop
;-------------------------------------------------------
Infinity:
    
    ; scroll the graphic horizontally
   lda #$00
scroll_h:     
    sta BG_1_hofs
    wai 
    wai
    
    adc #$01
    cmp #$FF
    bne scroll_h

    jmp Infinity   
;-------------------------------------------------------
.ENDS

;tile and palette
;------------------------------------------------------------------
.BANK 1 SLOT 0
.ORG 0
.SECTION "CharacterData"
    .INCLUDE "graphics/blue_head_4bpp.inc"
    .INCLUDE "palettes/blue_palette.inc"
.ENDS
