;animated head grid demo
;by Benjamin Santiago
;---------------------------------------------------------------

;includes
;---------------------------------------------------------------
;header for this ROM
.INCLUDE "inc/header.inc"

;code to start up SNES (clear registers)
;and macros for graphics
.INCLUDE "../../__inc/init_snes.inc"
.INCLUDE "inc/load_graphics.asm"

;variables
;---------------------------------------------------------------
.EQU temp_x     $0221
.EQU temp_y     $0222
.EQU temp_r     $0223
.EQU tile       $0224
.EQU tile_dir   $0225
.EQU tile_i     $0226
.EQU tile_ii    $0227
.EQU tile_ps    $0228
.EQU tile_psi   $0229
.EQU tile_r     $022A
.EQU tile_rc    $022B

;where the processor goes on reset
;---------------------------------------------------------------
.BANK   0 SLOT 0
.ORG    0
.SECTION "MainCode"

Start:
    ;start up the SNES
    InitSNES   

    stz tile
    stz tile_dir
    stz tile_i
    stz tile_ii
    stz tile_ps

    ;A/X/Y width (XY 16-bit & A 8-bit)   
    rep #$10    
    sep #$20

    ;2105       --> BG MODE / character size
    ;2105.b0    --> bg mode 1
    ;2015.b3    --> character priority (I think this puts sprites above BGs?)
    lda #%00001001
    sta $2105

    ;initial bg color (white $7FFF)
    stz $2121
    lda #$FF
    sta $2122
    lda #$7F
    sta $2122
    
    ; Load Palette for our tiles
    ; Sprite Palettes start at color 128
    LoadPalette SprPal, 128, 16     

    ; Load Tile data to VRAM
    LoadBlockToVRAM Sprite, $0000, $1000

    ;put RAM "copy" of sprites offscreen
    jsr SpriteInit    

    jsr position_sprites

    ; Setup video modes and other stuff,
    ; then turn on the screen
    jsr setup_video

    ;enable NMI 
    ;-------------------------------
    lda #$80
    sta $4200       

;main loop
;----------------------------------------------------------------------------------------------------------------
Infinity:
    wai 
    wai
    wai
    wai

    sep #$10
    sep #$20

    ;loop main tile
    lda tile_i
    cmp #$0D 
    bne +

    ;reset if at last tile
    stz tile_i
    jmp done_with_arithmetic
+
    inc tile_i

done_with_arithmetic:

    ldx tile_i
    lda.l sprite_table, X

    rep #$10

    sta tile_ii
    jsr position_sprites

    jmp Infinity    ;<-- we outttttt t t t t t t t
;----------------------------------------------------------------------------------------------------------------

;S U B R O U T I N E S

;initialize the sprites to be off-screen
;(this is only in RAM, still has to be 
;transferred to the OAM)
;---------------------------------------------------------------
SpriteInit:
	php	

	rep	#$30	;16bit mem/A, 16 bit X/Y
	
	ldx #$0000
    lda #$0001
_setoffscr:
    sta $0000,X
    inx
    inx
    inx
    inx
    cpx #$0200
    bne _setoffscr
;-------------------
	ldx #$0000
	lda #$5555
_clr:
	sta $0200, X		;initialize all sprites to be off the screen
	inx
	inx
	cpx #$0020
	bne _clr
;-------------------

	plp
	rts
;---------------------------------------------------------------

;---------------------------------------------------------------
position_sprites:
    php
    phx
    phy

    ;initial state
    ;-------------------------------------------
    rep #$10 
    sep #$20

    stz tile_r

    lda #$00
    sta temp_x

    lda #$00
    sta temp_y
    
    lda #$0020
    sta temp_r

    ldy #$00

sprite_props:
    ;transfer sprite tile number into the tile_ps register
    sep #$30
    ldx tile_psi
    lda.l sprite_table, X

    rep #$10
    sta tile_ps

    sep #$30

    ;manage tile psi
    ;-------------------------------
    lda tile_psi
    cmp #$0D 
    bne +

    stz tile_psi
    jmp dwic2

+
    inc tile_psi   

dwic2:
    rep #$10
    sep #$20
    ;-------------------------------

    
    ;sprite properties
    ;-------------------------------------------
    ;x coordinate
    lda temp_x
    sta $0000, Y
    iny

    ;y cooordinate
    lda temp_y
    sta $0000, Y
    iny

    ;tile number
    lda tile_ps
    sta $0000, Y
    iny

    ;other sprite properties
    lda #%00000000
    sta $0000, Y
    iny

    ;add x coordinate after each sprite
    ;-------------------------------------------
    lda temp_x
    cmp #$00

    lda temp_x
    adc #$1F
    sta temp_x

end_of_row:
    ;end of a row check
    ;-------------------------------------------
    lda temp_x
    cmp #$00
    bne sprite_props   

all_rows_done_check:
    ;all rows done check
    ;-------------------------------------------
    lda temp_r
    cmp #$E0
    bne +

    jmp end

+
    lda temp_r
    adc #$20
    sta temp_r

    ;add to y for next row
    lda temp_y
    adc #$20
    sta temp_y

    ;-------------------------------
    lda tile_i
    sta tile_psi

    inc tile_r

    lda tile_r
    sta tile_rc

    ;manage tile psi
manage_tile_psi:
    lda tile_psi
    cmp #$0D 
    bne +

    stz tile_psi
    jmp done_with_inc_check

+
    inc tile_psi   

done_with_inc_check:
    dec tile_rc 

    lda tile_rc
    cmp #$00
    bne manage_tile_psi 
    ;-------------------------------

    rep #$10
    sep #$20
    ;-------------------------------

    jmp sprite_props

    ;enable 9th x-bits
    ;-------------------------------------------
 end:    
    stz $0200
    stz $0201

    stz $0202
    stz $0203

    stz $0204
    stz $0205

    stz $0206
    stz $0207

    stz $0208
    stz $0209

    stz $020A
    stz $020B

    stz $020C
    stz $020D

    ply
    plx
    plp
    rts
;---------------------------------------------------------------


;set up the "general video"-type registers
;---------------------------------------------------------------
setup_video:
    php
    
    ;set XY/A
    rep #$10
    sep #$20
    
    stz $2102
    stz $2103
    
    ;transfer sprite data into OAM
    ;----------------------------------
	stz $2102		; set OAM address to 0
	stz $2103

	LDY #$0400
	STY $4300		; CPU -> PPU, auto increment, write 1 reg, $2104 (OAM Write)

	stz $4302

	stz $4303		; source offset

	LDY #$0220
	STY $4305		; number of bytes to transfer

	LDA #$7E
	STA $4304		; bank address = $7E  (work RAM)

	LDA #$01
	STA $420B		;start DMA transfer
	

    ;set sprite size to 32x32 at "small"
	lda #%10100000
    sta $2101

    lda #%00010000      ;Enable BG1
    sta $212C
    
    lda #$0F
    sta $2100           ;Turn on screen, full Brightness

    plp
    rts



;NMI (vblank) code
;---------------------------------------------------------------
VBlank:
	pha
	phx
	phy

    jsr setup_video

    ply 
    plx 
    pla
    rti
;---------------------------------------------------------------
.ENDS





;face graphic
;---------------------------------------------------------------
.BANK 1 SLOT 0
.ORG 0
.SECTION "CharacterData"

;define table for sprite tiles
;so they can be accessed via an incremented index
;---------------------------------------------------------------
sprite_table:
    .db $00, $04, $08, $0C, $40, $44, $48, $4C, $48, $44, $40, $0C, $08, $04

Sprite:
    .INCBIN "img/face_longAnimation__256x32.pic"

SprPal:
    .INCBIN "img/face_longAnimation__256x32.clr"
;---------------------------------------------------------------
.ENDS
