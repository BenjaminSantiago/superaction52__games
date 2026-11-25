; 4BPP FULL IMAGE BG
; by Benjamin Santiago
; 
; I first made this in like....2012 or 2014 or something like this, 
; currently modifying it for 2026 in the following ways:
; 
; * comments are actually correct (ie what register do what)
; * correcting some miscalculations (of bytes vs words)
; * using the register names from the SNES Dev. Manual


;includes
;-----------------------------------------------------------------
;header for this ROM, must be first
.INCLUDE "inc/header.inc"   

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
    InitSNES    ; Clear registers, etc.

    ; Load Palette to VRAM
    ;--------------------------------
    ;4bits per pixel so 16 palette entries

    LoadPalette blue_palette_16, 0, 16

    ; Load Tile data to VRAM
    ;---------------------------------
    ; Set BG1's Character VRAM offset to $0000 (word address)
    ; (snes has to know where to look for the data)
    stz BG12NBA           

    ; actually upload the data
    ; the third calculation is: 
    ; 256 * 224 (screen size) 
    ; * 4 (4bpp, 16 palette entries)
    ; /8 (8 bits per byte we are getting bytes to copy over)
    LoadBlockToVRAM blue_head, $0000, (256*224*4/8)	

    ; Load tile map data to VRAM
    ; ---------------------------------
    ; we are trying to store an image which is essentially
    ; just a bunch of tiles in a consecutive sequence.
    ; (i.e. we don't have an actual tilemap)

    ; set to increment when writing to $2119
    lda #%10000000     
    sta VMAIN

    ; Set BG1's Tile Map offset
    ; And the Tile Map size to 32x32
    lda #$3C            
    sta BG1SC

    ; set the starting address for the tilemap
    ; (it must be after $3800 because that is the end 
    ; of where we are storing the character data)
    ; we go to $3C00 so to avoid garbage data at the 
    ; bottom of the screen (tilemap being read as visual data)
    ldx #$3C00
    stx VMADDL

    ;get x and y ready
    ldx #$0000

;--------------------------------------------------------
blue_head_loop:      
    stx VMDATAL    ;put tile number into VRAM Low.
             
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
    sta TM

    ; Turn on screen, full Brightness
    lda #$0F
    sta INIDISP

    ;"Counter Enable" register this bit pattern enables NMI
    lda #%10000000
    sta NMITIMEN

    ;set the horizontal counter
    lda #$01
    lda HTIMEL

;main loop
;-------------------------------------------------------
Infinity:
    
    ; scroll the graphic horizontally
   lda #$00
scroll_h:     
    sta BG1HOFS
    wai 
    wai
    
    sbc #$01
    cmp #$00
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
