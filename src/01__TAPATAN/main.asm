;---------------------------------------------------------------
; SUPER ACTION 52 --> WEEK 02 --> TAPATAN
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
;---------------------------------------------------------------'
.EQU    gameMODE    $0221

; game modes
;-----------
; 00 --> title
; 01 --> options? 
; 02 --> game -> drop phase
; 03 --> game -> move phase
; 04 --> game -> game over

.EQU    BOARD       $0222 ; -> 0224
.EQU    BOARD_01    $0223
.EQU    BOARD_02    $0224
; The BOARD 
;----------
; it has 9 locations, 3 rows of 3. 
; each location is represented by 2 bits 
; empty         -> 00
; p1 occupied   -> 01
; p2 occupied   -> 10

; memory locations
; $0222         - $0223         - $0224
; 00 00 00 | 00 - 00 00 | 00 00 - 00

; GAME BOARD ROWS
;   TOP    | MIDDLE     | BOTTOM
; 00 00 00 | 00 - 00 00 | 00 00 - 00

.EQU sound_counter $0225




; M A I N  C O D E
;where the processor goes on reset
;---------------------------------------------------------------
.BANK 0 SLOT 0
.ORG 0
.SECTION "MainCode"

Start:
    ;start up the SNES
    InitSNES   

    ;"initialize" the "variables"
    ;------------------------------------------------------
    stz gameMODE
    stz BOARD
    stz sound_counter
    ;------------------------------------------------------

    jsr InitSoundCPU

     ;loop to transfer program into the SPC
    ;------------------------------------------------------
    ldx #$0000          ;(clear x start counter)

    SoundSendLoop:
    lda.l spc_program, X    ;first byte of stuff from spc program, offset by x

    sta $2141           ;chunk of stuff goes to $2141

    txa                 ;transfer x to a (counter var is now in a)
                        ;(x is being preserved for end of transfer)
    sta $2140           ;store offset in $2140

-       cmp $2140           ;wait for SPC to echo back the same value
    bne -           
    inx                 ;increment counter 
    cpx #spcend - spc_program
    bne SoundSendLoop

    ;end transfer
    ;------------------------------------------------------
    stz $2141       ;Mark end of data
                    ;why port 1--> 1 is the "command/data" port

    ldy #$0400      ;Set starting address of SPC code
    sty $2142       ;2142/ports 2 and 3 are the address ports

    inx
    inx             ;why two increments?
                    ;x was preserved earlier and 
                    ;the increments are just the protocol
    txa
    sta $2140       ;Tell SPC to begin executing its program
    ;------------------------------------------------------

    ;A/X/Y width (XY 16-bit & A 8-bit)   
    rep #$10    
    sep #$20

    ; Setup Video modes and other stuff, then turn on the screen
    jsr SetupVideo

    lda #$80
    sta $4200       ; Enable NMI

;main loop
;---------------------------------------------------------------
forever:
    wai;t for an interrupt y'all!
    lda $2140
    cmp #$EB 
    bne done_with_spc

    lda #$EB
    sta $2140

done_with_spc:
    ;TITLE
    ;----------------------------------------------------------
    ; title game code 
    ; --> display title
    ;----------------------------------------------------------

    ;GAME 
    ;----------------------------------------------------------

    ; --> drop phase
    ; ----> start player 1
    
    ; ----> current player drops
    
    ; --------> selection sound as they move locations
    ; --------> make sure location is legal
    ; --------> change color/make a bad ding if they try to drop
    ; --------> nice ding / animation if it works
    ; --------> update connector graphics
     
    ; --------> check win conditions 
    ; (only do this at the very end)

    ; ----> switch to other player (back up to current player drops)

    ; --> move phase

    ; ----> current player moves

    ; --------> selection sound as they move locations
    ; --------> player selects one of their things
    ; --------> player selects legal location to move to
    ; --------> process move

    ; --------> check win conditions

    ; --------> switch players
    
    ; --> game over 
    ; ----> who won?
    ; ----> show that player won 

    ; --> reset stuff
    ; --> go back to title    
    ;----------------------------------------------------------

    ; test sound
    lda sound_counter
    cmp #$80
    bne +

    stz sound_counter
    ; play sound
    lda #$BE 
    sta $2140
    
+   inc sound_counter

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
    ;------------------------------------------------------


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
	
	lda #%10100000
    sta $2101

    lda #%00010000      ;Enable BG1
    sta $212C
    
    lda #$0F
    sta $2100           ;Turn on screen, full Brightness

    plp
    rts
;---------------------------------------------------------------

;NMI (vblank) code
;---------------------------------------------------------------
VBlank:
	pha
	phx
	phy
    

	PLY 
	PLX 
	PLA 

    sep #$20
    RTI

;---------------------------------------------------------------
; (END of SUBROUTINES)
.ENDS

; graphics
;---------------------------------------------------------------
.BANK 1 SLOT 0
.ORG 0
.SECTION "graphic_and_audio__includes"

spc_program:
    .incbin "spc__playWithCollide.bin"
    .incbin "audio/guitar_palmmuted__C__32k.BRR"
spcend:
        .db $FF
;---------------------------------------------------------------
.ENDS
