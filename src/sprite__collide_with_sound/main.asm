;sprite screen collision with sound at edge of screen
;by Benjamin Santiago
;(based on bazz example)
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
;these two are to determine if the sprite should go 
;go back or forth in each dimension
.EQU Y_dir      $0221
.EQU X_dir      $0222

;this is a flag to determine if the background 
;should be blue or not
.EQU bg_flash   $0223

;counter to inc and compare to if bg should be flashing or not
.EQU bg_c       $0224





;where the processor goes on reset
;---------------------------------------------------------------
.BANK 0 SLOT 0
.ORG 0
.SECTION "MainCode"

Start:
    ;start up the SNES
    InitSNES   

    ;"initialize" the "variables"
    stz X_dir
    stz Y_dir
    stz bg_flash
    stz bg_c

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
    ;------------------------------------------------------


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
    LoadPalette sprite_palette, 128, 16     ; Sprite Palettes start at color 128

    ; Load Tile data to VRAM
    LoadBlockToVRAM sprite, $0000, $0800

    ;put RAM "copy" of sprites offscreen
    jsr SpriteInit    

    ;initialize sprite properties
    ;set x (screen *.5 / width of sprite)
    lda #32
    sta $0000
    
    ;set y (sceen.height * .5/height of sprite)
    lda #(224/2 - 16)
    sta $0001
    
    ;first tile is zeroth one
    stz $0002

    ;sprite_byte_3.b6   --> horizontal flip
    ;sprite_byte_3.b4-5 --> sprite priority 3 (above bgs?)
    lda #%00110000
    sta $0003
    
    ;enable 9th x-bits
    lda #%01010100
    sta $0200
    
    ; Setup Video modes and other stuff, then turn on the screen
    jsr SetupVideo

    lda #$80
    sta $4200       ; Enable NMI

;main loop
;---------------------------------------------------------------
Infinity:
    wai 

    lda $2140
    cmp #$EB 
    bne done_with_spc

    lda #$EB
    sta $2140

done_with_spc:

    ;update values for background values
    ;---------------------------------------------
    ;see if bg_flash is 1 or 0
    lda bg_flash
    cmp #$01
    bne +

    ;see if counter is done
    lda bg_c
    cmp #$03
    bne for

    ;we are done so zero out counter
    ;and bg flash variable
    stz bg_c
    stz bg_flash
    bra +

for
    ;(if counter isn't at the max, then inc)
    inc bg_c
+
    ;manage sprite 01 --> x
    ;---------------------------------------------
    ;check if sprite hit the right side 
    lda $0000
    cmp #(256 - 32)
    bne +

    lda #$01
    sta bg_flash
    stz X_dir

    ;play sound
    lda #$BE 
    sta $2140

+
    ;check if sprite hit the left side
    lda $0000
    cmp #$00
    bne +

    lda #$01
    sta bg_flash
    lda #$01
    sta X_dir

    ;play sound
    lda #$BE 
    sta $2140
+
    ;---------------------------------------------

    ;manage sprite 01 --> y
    ;---------------------------------------------
y_check:
    ;check if sprite hit the bottom
    lda $0001
    cmp #(224 - 32)
    bne + 

    lda #$01
    sta bg_flash
    stz Y_dir

    ;play sound
    lda #$BE 
    sta $2140

+
    ;check if sprite hit the top
    lda $0001
    cmp #$00
    bne +

    lda #$01
    sta bg_flash
    sta Y_dir

    ;play sound
    lda #$BE 
    sta $2140
+
    
    ;move sprites according to the direction 
    ;already determined
    ;---------------------------------------------
x_move:
    lda X_dir
    cmp #$00
    bne +

    lda $0000
    sbc #$01
    sta $0000
    jmp y_move

+
    lda $0000
    adc #$01
    sta $0000

y_move:
    lda Y_dir 
    cmp #$00
    bne +

    lda $0001
    sbc #$01
    sta $0001
    jmp Infinity

+
    lda $0001
    adc #$0
    sta $0001
    ;---------------------------------------------

    jmp Infinity    ;<-- we outttttt t t t t t t t
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



;NMI (vblank) code
;---------------------------------------------------------------
VBlank:
	pha
	phx
	phy
    
    rep #$10    
    sep #$20

    ;check if bg is flashing
    lda bg_flash
    cmp #$01
    bne +

    ;make BG blue ($72A5)
    stz $2121
    lda #$A5
    sta $2122
    lda #$72
    sta $2122
    jmp pre_setup

+
    ;otherwise set to white ($7FFF)
    stz $2121
    lda #$FF
    sta $2122
    lda #$7F
    sta $2122    

pre_setup:    

    jsr SetupVideo
    
	PLY 
	PLX 
	PLA 

    sep #$20
    RTI

;---------------------------------------------------------------
.ENDS

;face graphic
;---------------------------------------------------------------
.BANK 1 SLOT 0
.ORG 0
.SECTION "graphic_and_audio__includes"

sprite:
    .incbin "img/face__32x32__.pic"

sprite_palette:
    .incbin "img/face__32x32__.clr"


spc_program:
    .incbin "spc__playWithCollide.bin"
    .incbin "audio/guitar_palmmuted__C__32k.BRR"
spcend:
        .db $FF
;---------------------------------------------------------------
.ENDS
