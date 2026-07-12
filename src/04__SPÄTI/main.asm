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
.ASCIITABLE
    MAP "A" TO "Z" = $00
.ENDA

;game modes
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

    
    lda #%10101010
    sta $0000

    lda #%01010101
    sta $0001
    
    ;"initialize" the "variables"
    ;---------------------------------
    stz gameMODE
    stz is_GAME_paused

    stz SCREEN__brightness


    ;---------------------------------

    ;A/X/Y width (XY 16-bit & A 8-bit)   
    rep #$10    
    sep #$20

    ; BG MODE
    lda #%00001001
    sta $2105
   
    ; Load Palettes & Graphics
    ;---------------------------------
    LoadPalette Alphabet__01_palette, 0,   16

    ; HOW TO MAKE SURE THESE NUMBERS ARE ACCURATE?
    LoadBlockToVRAM Alphabet__01_graphic, $0000, $1000
    ;---------------------------------

    lda $0002
    cmp #$F0
    bne @no_secret

    lda #$00
    sta $2121

    lda #$1F
    sta $2122

    lda #$00
    sta $2122
@no_secret:
    ;tilemap
    ;---------------------------------
    ; set to increment when writing to $2118
    lda #%10000000     
    sta $2115

    lda #$70            ; Set BG1's Tile Map offset
    sta $2107           ; And the Tile Map size to 32x32

    rep #$30

    ; set the starting address for the tilemap
    ; (it must be at $7000 because that is the end 
    ; of where we are storing the character data)
    ldx #$7000
    stx $2116

    ;get x 
    ldx #$0000

    ; add the message
loop_for_bg:
    lda.l howl, x
    sta $2118   ;put tile number into VRAM low
    inx
    inx
    cpx #howl_end-howl
    bne loop_for_bg

    ; make the rest of the screen blank (00 would be A)
loop_for_empty:
    lda #$0454
    sta $2118
    inx
    inx
    cpx #$0E00
    bne loop_for_empty

    rep #$10
    sep #$20
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

    ;-----------------------------------------
@end_interrupt:
    ply
    plx
    pla
    plp

    rep #$10
    sep #$20

    rti

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
;---------------------------------------------------------------
.ENDS
