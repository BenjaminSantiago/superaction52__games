; adapting C functions from SNES GSS to assembly

; ------------------------------------------------
.define SCMD_NONE				$00
.define SCMD_INITIALIZE			$01
.define SCMD_LOAD				$02
.define SCMD_STEREO				$03
.define SCMD_GLOBAL_VOLUME		$04
.define SCMD_CHANNEL_VOLUME		$05
.define SCMD_MUSIC_PLAY 		$06
.define SCMD_MUSIC_STOP 		$07
.define SCMD_MUSIC_PAUSE 		$08
.define SCMD_SFX_PLAY			$09
.define SCMD_STOP_ALL_SOUNDS	$0a
.define SCMD_STREAM_START		$0b
.define SCMD_STREAM_STOP		$0c
.define SCMD_STREAM_SEND		$0d

.define APU0				    $2140
.define APU1				    $2141
.define APU01				    $2140
.define APU2				    $2142
.define APU3				    $2143
.define APU23				    $2142
; ------------------------------------------------


; ------------------------------------------------
;void spc_init(void)
SPC__init:
    ;static unsigned int i,size;    
    ;size=spc700_code_1[0]+(spc700_code_1[1]<<8);
    rep #$20
    lda.l spc700_code_1
    sta spc_size

    ;spc_music_load_adr=
    ;spc700_code_1[14]+(spc700_code_1[15]<<8);
    lda.l spc700_code_1 + 14
    sta spc_music_load_adr
    sep #$20

    ;WORK ON THIS LATER    
    ;spc_stream_enable=FALSE;

    ;nmi_enable(FALSE);
    stz NMITIMEN
    
    ;spc_load_data(0x0200,size,spc700_code_1+2);
    rep #$20
    lda #:spc700_code_1
    pha 

    lda #spc700_code_1+2
    pha 

    lda spc_size
    pha 

    lda #$0200
    pha

    jsl SPC__load_data
    pla
    pla
    pla
    pla
    sep #$20

    ;WORK ON THIS LATER
    ;if(size<32766)
    ;{

    ;}
    ;else
    ;{
    ;	spc_load_data(0x0200,32766,spc700_code_1+2);
    ;	spc_command(SCMD_LOAD,0);
    ;	spc_load_data(0x81fe,size-32766,spc700_code_2);

    ;spc_command(SCMD_INITIALIZE,0);
    rep #$20
    
    lda #$0000
    pha 

    lda #SCMD_INITIALIZE
    pha 

    jsl SPC__command
    pla
    pla
    sep #$20

    ;nmi_enable(TRUE);
    lda #$81
    sta NMITIMEN

    rtl
; ------------------------------------------------

; ------------------------------------------------
;void spc_load_data(unsigned int adr,unsigned int size,const unsigned char *src)
SPC__load_data:

    php
	rep #$30
	
	sei

	sep #$20
	lda.b #$aa
-
	cmp.l APU0
	bne -

	rep #$20
	lda 11,s				;srch
	sta.b sneslib_ptr+2
	lda 9,s					;srcl
	sta.b sneslib_ptr+0
	lda 7,s					;size
	tax
	lda 5,s					;adr
	sta.l APU23
	
	sep #$20
	lda.b #$01
	sta.l APU1
	lda.b #$cc
	sta.l APU0
	
-
	cmp.l APU0
	bne -
	
	ldy.w #0
	
_load_loop:

	xba
	lda.b [sneslib_ptr],y
	xba
	tya
	
	rep #$20
	sta.l APU01
	sep #$20
	
-
	cmp.l APU0
	bne -
	
	iny
	dex
	bne _load_loop
	
	xba
    lda.b #$00
    xba
	clc
	adc.b #$02
	rep #$20
	tax
	
	lda.w #$0200			;loaded code starting address
	sta.l APU23

	txa
	sta.l APU01
	sep #$20
	
-
	cmp.l APU0
	bne -
	
	rep #$20
-
	lda.l APU0			;wait until SPC700 clears all communication ports, confirming that code has started
	ora.l APU2
	bne -
	
	cli					;enable IRQ
	
	plp
	rtl
; ------------------------------------------------

; ------------------------------------------------
SPC__command:
	php
	rep #$30
	
	lda 7,s				;param
	sta.b gss_param
	lda 5,s				;command
	sta.b gss_command
	
	jsl spc_command_asm

	plp
	rtl
; ------------------------------------------------

; ------------------------------------------------
spc_command_asm:

	sep #$20

-
	lda.l APU0
	bne -

	lda.l APU3			;the driver increments APU3 for every command it takes, remember
	pha					;the current value to detect the acknowledge

	rep #$20

	lda.b gss_param
	sta.l APU23
	lda.b gss_command
	sep #$20
	xba
	sta.l APU1
	xba
	sta.l APU0

	cmp.b #SCMD_LOAD	;don't wait acknowledge
	beq +

-
	lda.l APU0			;acknowledged when the command code is echoed back, but the driver
	bne +				;clears it again when the command is done and an interrupt here can
	lda.l APU3			;miss that, so also accept APU3 changing, which stays changed
	cmp 1,s
	beq -

+
	pla

	rtl
; ------------------------------------------------

; ------------------------------------------------
;/*play sound effect*/
;void sfx_play(
    ;unsigned int chn,
    ;unsigned int sfx,
    ;unsigned int vol,
    ;int pan);
SPC__sfx_play:

	php
	rep #$30

	lda 11,s			;pan
	bpl +
	lda.w #0
+
	cmp.w #255
	bcc +
	lda.w #255
+

	xba
	and.w #$ff00
	sta.b gss_param
	
	lda 7,s				;sfx number
	and.w #$00ff
	ora.b gss_param
	sta.b gss_param

	lda 9,s				;volume
	xba
	and.w #$ff00
	sta.b gss_command

	lda 5,s				;chn
	asl a
	asl a
	asl a
	asl a
	and.w #$00f0
	ora.w #SCMD_SFX_PLAY
	ora.b gss_command
	sta.b gss_command

	jsl spc_command_asm

	plp
	rtl
; ------------------------------------------------

; ------------------------------------------------
SPC__music_play:
    ;/*play music*/
    ;void music_play(const unsigned char *data)
    ;{
    ;	static unsigned int size;
    ;
    ;	size=data[0]+(data[1]<<8);
    ;
    ;	nmi_enable(FALSE);
    ;	
    ;	spc_command(SCMD_MUSIC_STOP,0);
    ;	spc_command(SCMD_LOAD,0);
    ;	spc_load_data(spc_music_load_adr,size,data+2);
    ;	spc_command(SCMD_MUSIC_PLAY,0);
    ;	
    ;	nmi_enable(TRUE);
    ;}
    rtl

