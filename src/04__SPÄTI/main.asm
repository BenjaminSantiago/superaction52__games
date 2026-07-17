;---------------------------------------------------------------
; SUPER ACTION 52 --> WEEK 03 --> Text Game
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
; GAME MODE
;---------------
; use bits 0 and 1 in order to indicate
; 00 --> init
; 01 --> fading in
; 10 --> fading out
; 11 --> loading vram data

;then upper 6 bits are an index to a game mode 
;right now:
;000000 --> title
;000001 --> first image

.EQU gameMODE $0221
.EQU is_GAME_paused $0222

; CONTROLLER
; c --> "current"
; p --> "pressed" this frame
; h --> "held" from previous frame
;-------------------------------
.EQU joy1H__c   $0223
.EQU joy1H__p   $0224
.EQU joy1H__h   $0225

.EQU joy1L__c   $0226
.EQU joy1L__p   $0227
.EQU joy1L__h   $0228

.EQU joy2H__c   $0229
.EQU joy2H__p   $022A
.EQU joy2H__h   $022B

.EQU joy2L__c   $022C
.EQU joy2L__p   $022D
.EQU joy2L__h   $022E
;-------------------------------

.EQU SCREEN__brightness $022F

; this is SCRATCH for holding
; which numbered chunk of 
; vram we are uploading to
.EQU vram_chunk $0230


; this is for making the palette fade to white
;-------------------------------
; which number in the palette $00 - $10 (16 entries)
.EQU palette_index $0231

; the offset of the word of the palette entry
.EQU palette_offset $0232 ; <-- a word (2 bytes)

; which direction we want to fade 
; 0 --> increase
; 1 --> decrease
.EQU palette_fade_direction $0234 ;<--FLAG

; I think we need 3 bytes for this
; this is the location where the color values are coming from 
.EQU palette_table_pointer $00 ;<-- direct page for Y
.EQU palette_target_gameMODE $235
;-------------------------------

;---------------------------------------------------------------

;where the processor goes on reset
;---------------------------------------------------------------
.BANK 0 SLOT 0
.ORG 0
.SECTION "MainCode"

Start:
    ;A/X/Y width (XY 16-bit & A 8-bit)   
    rep #$10    
    sep #$20

    lda $0000
    cmp #%10101010
    beq @secret_byte_2

    bra @init

@secret_byte_2: 
    lda $0001
    cmp #%01010101
    beq @secret_pass

    bra @init  

@secret_pass:
    lda #%11110000
    sta $0002

@init:
    ;start up the SNES
    InitSNES   

    
    ;lda #%10101010
    ;sta $0000
    ;
    ;lda #%01010101
    ;sta $0001
    
    ;"initialize" the "variables"
    ;---------------------------------
    stz gameMODE
    stz is_GAME_paused

    stz SCREEN__brightness

    stz vram_chunk
    stz palette_index
    stz palette_offset
    stz palette_offset+1
    stz palette_fade_direction
    stz palette_table_pointer
    stz palette_target_gameMODE
    ;---------------------------------

    ;A/X/Y width (XY 16-bit & A 8-bit)   
    rep #$10    
    sep #$20

    ; BG MODE
    lda #%00001001
    sta $2105
   
    ; Load Palettes & Graphics
    ;---------------------------------
    LoadPalette Spati__title_palette,   0,  16
    
    ; (I have some garbage getting passed to the bg layers
    ; not sure why it is happening so for now, 
    ; making all the other background palettes white)
    LoadPalette all_white_palette, 16, 16
    LoadPalette all_white_palette, 32, 16
    LoadPalette all_white_palette, 48, 16
    LoadPalette all_white_palette, 64, 16
    LoadPalette all_white_palette, 80, 16
    LoadPalette all_white_palette, 96, 16
    LoadPalette all_white_palette, 112, 16
    LoadPalette all_white_palette, 128, 16
    LoadPalette all_white_palette, 144, 16

    ; HOW TO MAKE SURE THESE NUMBERS ARE ACCURATE?
    LoadBlockToVRAM Spati__title_tiles, $0000, $0B00
    LoadBlockToVRAM Spati__title_map,   $0800, $0700
    ;---------------------------------

    ;pass tilemap location
    lda #$08
    sta $2107

    ; check direct page on reset
    ;;---------------------------------
    ;lda $0002
    ;cmp #$F0
    ;bne @no_secret
;
    ;lda #$00
    ;sta $2121
;
    ;lda #$1F
    ;sta $2122
;
    ;lda #$00
    ;sta $2122
    ;;---------------------------------  
;@no_secret:

    ;(sprites don't matter yet)
    ;---------------------------------
    ;put RAM "copy" of sprites offscreen
    ;jsr SpriteInit    
    
    ; Setup Video modes and other stuff, then turn on the screen
    jsr SetupVideo
    ;---------------------------------

    ; Enable NMI
    lda #$81
    sta $4200       

;main loop
;---------------------------------------------------------------
forever:
    wai;t for interrupt

    rep #$10
    sep #$20 

    ;PAUSE check
    ;-------------------------
pause: 
    ;only check if not at the title (0)
    lda gameMODE
    beq @not_paused

@pause_check:
    jsr CHECK__pause 
    beq @not_paused
    jmp forever
@not_paused:
    ;-------------------------

check_controls:
    lda gameMODE
    bne go_to_game@done_with_controls

    ;from the title screen, 
    ;wait for P1 to press any
    ;non-directional button press
    lda joy1H__p
    and #%11110000
    bne go_to_game

    lda joy1L__p
    and #%11110000
    bne go_to_game

    bra go_to_game@done_with_controls

go_to_game:
    ;set game mode to 
    ;000000 --> title
    ;10     --> fading out
    lda #%00000010
    sta gameMODE
@done_with_controls:

main_game:
    lda gameMODE
    cmp #$01
    beq @first_bg    

    jmp @done_with_main_game

@first_bg:

@done_with_main_game:
    jmp forever    ;<-- we outttttt t t t t t t t
;---------------------------------------------------------------


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
InitSoundCPU:
    php
    pha
    phx

    rep #$30
    sep #$20

    ;initialize transfer
    ;------------------------------------------------------
    ;make sure #$AA and #$BB are at $2140 and $2141 
    ;respectively. this is makes sure that the SPC is ready
    ;the original code didn't do this but worked fine
    lda #$AA
-
    cmp $2140
    bne -
-
    lda #$BB
    cmp $2141
    bne -   
    
    ldx #$0400      ;Target SPC address for program, why #$400?
                    ;(because that's where SPCTEST.asm "orgs" to)
    stx $2142       ;why port 2 --> port 2 is address for data

    lda #$01        ;what is 1  --> value to initialize transfer
    sta $2141       ;why port 1 --> port 1 is status of transfer

    ;wait for SPC sync
    ;when you read CC on 2140 from SPC
    ;everything is good
    lda #$CC
    sta $2140
-       cmp $2140       
    bne -

    plx
    pla
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
;	stz $2102		; set OAM address to 0
;	stz $2103
;
;	LDY #$0400
;	STY $4300		; CPU -> PPU, auto increment, write 1 reg, $2104 (OAM Write)
;
;	stz $4302
;
;	stz $4303		; source offset
;
;	LDY #$0220
;	STY $4305		; number of bytes to transfer
;
;	LDA #$7E
;	STA $4304		; bank address = $7E  (work RAM)
;
;	LDA #$01
;	STA $420B		;start DMA transfer
	
	lda #%10100000
    sta $2101

    lda #%00010001      ;Enable BG1
    sta $212C
    
    lda #$0F
    sta $2100           ;Turn on screen, full Brightness

    plp
    rts
;---------------------------------------------------------------

; PAUSING
;---------------------------------------------------------------
CHECK__pause:
    lda joy1H__p
    ;ora joy2H__p <-- if the game is two players add this
    and #%00010000
    beq @process_pause

    ;toggle pause flag
    lda is_GAME_paused
    eor #%00000001
    sta is_GAME_paused

@process_pause:
    ;use this to set Z flag
    lda is_GAME_paused 
    rts
;---------------------------------------------------------------


;NMI (vblank) code
;---------------------------------------------------------------
VBlank:
    php
	pha
	phx
	phy
    
    rep #$10    
    sep #$20
    ;-----------------------------------------
    
    
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
    ;--------------------------------

    ;PAUSE
    ;--------------------------------
    ;(currently we just dim the screen)
    lda is_GAME_paused
    beq @brighten_screen

    ; game is paused
    lda SCREEN__brightness
    cmp #$08
    bne @dim_screen

    bra @done_with_pause
    
@dim_screen:
    dec SCREEN__brightness
    lda SCREEN__brightness
    sta $2100
    jmp @done_with_pause

@brighten_screen: 
    ;turn on screen
    ;(if not on)
    lda SCREEN__brightness
    cmp #$0F
    beq  @done_with_pause

    inc SCREEN__brightness
    lda SCREEN__brightness
    sta $2100
@done_with_pause:
    ;--------------------------------


    ; CHECK GAME MODE
    ;-------------------------------------------------
check_the_gameMODE:
    ;000000 --> title 
    ;10     --> fade out
    lda gameMODE
    cmp #%00000010
    bne +
    jmp title__fadeOUT
+
    ;000001 --> screen 1 
    ;11     --> load VRAM
    lda gameMODE
    cmp #%000000111
    beq screen01@loadVRAM

    ;000001 --> screen 1
    ;00     --> init
    lda gameMODE
    cmp #%00000100
    bne +
    jmp screen01@init

+    
    ;000001 --> screen 1
    ;01     --> fade in
    lda gameMODE
    cmp #%00000101
    bne +
    jmp screen01@fade_in
+

    ;000010 --> screen 1 + text
    ;00     --> init
    lda gameMODE
    cmp #%00001000
    bne +

    jmp screen01_text@init

+
    jmp end_interrupt

    ; TITLE --> fade out
    ;--------------------------------
title__fadeOUT:   
    ; initialize values we need

    ; index in the palette
    lda #$00
    sta palette_index

    ; the offset of table value
    ldy palette_offset

    ; zero is out 
    stz palette_fade_direction

    ; get pointer values
    lda #<title__DIPtoWHITE@begin
    sta palette_table_pointer

    lda #>title__DIPtoWHITE@begin
    sta palette_table_pointer+1

    lda #:title__DIPtoWHITE@begin
    sta palette_table_pointer+2

    ; game mode we target afterwards
    lda #%00000111
    sta palette_target_gameMODE
    jmp palette_loop

    ; load BG1 in chunks
    ; (THIS NEEDS TO BE GENERIC)
    ;--------------------------------
screen01:
@loadVRAM:    
    lda vram_chunk
    beq @loadVRAM__chunk00

    lda vram_chunk
    cmp #$01
    beq @loadVRAM__chunk01

    lda vram_chunk
    cmp #$02
    beq @loadVRAM__chunk02

    lda vram_chunk
    cmp #$03
    beq @loadVRAM__chunk03

    jmp @loadMAP

@loadVRAM__chunk00:
    LoadBlockToVRAM FIELDclosed__tiles,     $0000, $0800
    inc vram_chunk
    jmp @done_with_VRAMchunks

@loadVRAM__chunk01:
    LoadBlockToVRAM FIELDclosed__tiles+$0800, $0400, $0800
    inc vram_chunk
    jmp @done_with_VRAMchunks

@loadVRAM__chunk02:
    LoadBlockToVRAM FIELDclosed__tiles+$1000, $0800, $0800
    inc vram_chunk
    jmp @done_with_VRAMchunks

@loadVRAM__chunk03:
    LoadBlockToVRAM FIELDclosed__tiles+$1800, $0C00, $0120
    inc vram_chunk
    jmp @done_with_VRAMchunks

@loadMAP:
    LoadBlockToVRAM FIELDclosed__map, $1400, $0700
        
    ; link tilemap
    lda #$14
    sta $2107

    ;000001 --> screen 01
    ;00     --> init
    lda #%00000100
    sta gameMODE
@done_with_VRAMchunks:
    jmp end_interrupt
    ;--------------------------------

@init:
    ;max out palette init
    ldy #$01E0
    sty palette_offset
    
    ;going up the table
    lda #$01
    sta palette_fade_direction

    ;point 'em up
    lda #<FIELDclosed__toWHITE__begin
    sta palette_table_pointer

    lda #>FIELDclosed__toWHITE__begin
    sta palette_table_pointer+1

    lda #:FIELDclosed__toWHITE__begin
    sta palette_table_pointer+2
    
    lda #%00001000
    sta palette_target_gameMODE

    ; we are done with in it, 
    ; advance game mode
    ;screen 01, fade in
    lda #%00000101
    sta gameMODE
@fade_in:
    lda #$00
    sta palette_index

    ldy palette_offset

    ; this should be a subroutine.
palette_loop:
    lda palette_index
    sta $2121

    ;put color
    lda [palette_table_pointer], y
    sta $2122
    iny

    lda [palette_table_pointer], y
    sta $2122
    iny

    inc palette_index
    lda palette_index
    cmp #$10
    bne palette_loop

    lda palette_fade_direction
    beq @up
@down: 
    rep #$20
    lda palette_offset
    beq @down_done

    sec 
    sbc #$0020
    sta palette_offset
    sep #$20
    bra @done

@down_done: 
    sep #$20
    lda palette_target_gameMODE
    sta gameMODE
    bra @done

@up:
    sty palette_offset
    cpy #$0200
    bne end_interrupt

    lda palette_target_gameMODE
    sta gameMODE
@done:
    ;-----------------------------------------

screen01_text:
@init:
    ;turn on other bg
    lda #%00000011
    sta $212C
    ; BG1 character base = $0000, BG2 character base = $2000.
    lda #$20
    sta $210B

    LoadBlockToVRAM Alphabet__01_graphic, $2000, $0C00
    
    ;LoadPalette Alphabet__01_palette, 16, 16
    LoadBlockToVRAM howl, $2800, howl_end-howl
    lda #$28
    sta $2108







end_interrupt:
    rep #$10
    sep #$20
    ply
    plx
    pla
    plp

    rti

;---------------------------------------------------------------

;---------------------------------------------------------------
    .INC "inc/FIELDclosed__toWHITE.inc"
    .INC "inc/title__DIPtoWHITE.inc"
;---------------------------------------------------------------
.ENDS

;face graphic
;---------------------------------------------------------------
.BANK 1 SLOT 0
.ORG 0
.SECTION "graphic_and_audio__includes"

Alphabet__01_palette:
    .INCBIN "_graphics/Alphabet__01_strip.clr"
Alphabet__01_graphic:
    .INCBIN "_graphics/Alphabet__01_strip.pic"
    
    .INC "inc/howl.inc"

Spati__title_palette:
    .INCBIN "_graphics/SPATItitle__palette.clr"
Spati__title_tiles:
    .INCBIN "_graphics/SPATItitle__tiles.pic"
Spati__title_map:
    .INCBIN "_graphics/SPATItitle__tilemap.map"

FIELDclosed__palette:
    .INCBIN "_graphics/FIELDclosed__86.clr"
FIELDclosed__map:
    .INCBIN "_graphics/FIELDclosed__86.map"
FIELDclosed__tiles:
    .INCBIN "_graphics/FIELDclosed__86.pic"


;---------------------------------------------------------------
.ENDS
