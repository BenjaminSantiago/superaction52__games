;includes
;-----------------------------------------------------------------
.INCLUDE "inc/header.inc"   ;<-- header for this ROM, must be first

;universal includes
.INCLUDE "../../__inc/registers.inc"
.INCLUDE "../../__inc/init_snes.inc"

.INCLUDE "inc/LoadGraphics.asm"


;main stuff
;------------------------------------------------------------------
.BANK 0 SLOT 0
.ORG 0
.SECTION "MainCode"

Start:
    ; Clear registers, etc.
    InitSNES    

    ; Load Palette to CGRAM
    ;--------------------------------
    ;8bits per pixel so 256 palette entries

    LoadPalette blue_palette_256, 0, 256

    ; Load Tile data to VRAM
    ;--------------------------------
    stz BG12NBA           ; Set BG1's Character VRAM offset to $0000 (word address)

    ;to determine size (3rd parameter)
    ;you must, do this
    ;8 * color depth (in bits) * number_of_characters

    ;we need to transfer two blocks because of our ROM mapping (LoROM)

    LoadBlockToVRAM blue_head_8bpp_1, $0000, $7000	
    LoadBlockToVRAM blue_head_8bpp_2, $37E0, $7200

    ; Load tile map data to VRAM
    ; ---------------------------------
    ; we are trying to store an image which is 
    ; just a bunch of tiles in a consecutive sequence.

    ; set to increment when writing to $2118
    lda #%10000000     
    sta VMAIN

    lda #$70            ; Set BG1's Tile Map offset
    sta BG1SC           ; And the Tile Map size to 32x32

    ; set the starting address for the tilemap
    ; (it must be at $E000 because that is the end 
    ; of where we are storing the character data)
    ldx #$7000
    stx VMADDL

    ldx #$0000
;--------------------------------------------------------
blue_head_loop:      
    stx VMDATAL    ;put tile number into VRAM Low.
             
    inx
    cpx #$0E00             
    bne blue_head_loop
;--------------------------------------------------------

    ;8bpp/256 color images
    ;which has that option for bg 3
    lda #%00000011   
    sta BGMODE    

    lda #$01            ; Enable BG1
    sta TM

    lda #$0F
    sta INIDISP           ; Turn on screen, full Brightness

    lda #%10000000
    sta NMITIMEN      ;<--"Counter Enable" register this bit pattern enables NMI

    ;set the horizontal counter
    lda #$01
    lda $4207

;main loop
;-------------------------------------------------------
Infinity:


    jmp Infinity   
;-------------------------------------------------------
.ENDS

;tile and palette
;------------------------------------------------------------------
.BANK 1 SLOT 0
.ORG 0
.SECTION "CharacterData_1" 
    .INCLUDE "graphics/blue_head_8bpp_1.inc"
.ENDS

.BANK 2 SLOT 0
.ORG 0
.SECTION "CharacterData_2" 
    .INCLUDE "graphics/blue_head_8bpp_2.inc"
.ENDS

.BANK 3 SLOT 0
.ORG 0
.SECTION "PaletteData" 
    .INCLUDE "palettes/blue_palette_256.inc"
.ENDS