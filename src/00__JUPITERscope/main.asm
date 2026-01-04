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

loop_for_bg:
    stx $2118   ;put tile number into VRAM low
    inx
    cpx #$0E00
    bne loop_for_bg

    ;we have a 4bpp graphic (16 palette entries)
    ;so we want to use background mode 1
    ;which has that option for bg 1
    lda #%00000001        
    sta $2105    

    lda #$01            ; Enable BG1
    sta $212C

    lda #$0F
    sta $2100           ; Turn on screen, full Brightness

;loop
;------------------------------------------
forever:
    jmp forever

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
.ENDS
;------------------------------------------