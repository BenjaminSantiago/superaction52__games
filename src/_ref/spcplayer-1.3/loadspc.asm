; SNES SPC loader
; /Mic, 2010

; Based on code by Joe Lee


 ; The starting SNES ROM bank of the 64kB SPC RAM dump
 .equ SPC_DATA_BANK		2
 ; The base address of the SNES ROM chunk containing DSP and SPC register values
 .equ SPC_REG_ADDR		$18000
 
 ; The initialization code will be written to this address in SPC RAM if no better location is found
 .equ SPC_DEFAULT_INIT_ADDRESS	$ff70
 
 ; The length of our init routine in bytes
 .equ SPC_INIT_CODE_LENGTH 	$2b 
 
 ; The length of our fastloader routine in bytes
 .equ SPC_FASL_LENGTH	   	$32
 
 
 ; Zero page variables
 .equ spcSongNr		$f0
 .equ spcMirrorVal	$f1
 .equ spcSourceAddr	$f2	; Three bytes!
 .equ spcExecAddr	$f5	; Two bytes!
 .equ spcScanVal	$f7
 .equ spcScanLen	$f8
 

 .macro sendMusicBlockM ; srcSeg srcAddr destAddr len
	; Store the source address \1:\2 in musicSourceAddr.
	sep     #A_8BIT
	lda     #\1
	sta     spcSourceAddr + 2
	rep     #A_8BIT
	lda     #\2
	sta     spcSourceAddr

	; Store the destination address in x.
	; Store the length in y.
	rep     #XY_8BIT
	ldx     #\3
	ldy     #\4
	jsr     CopyBlockToSPC
 .endm
 
 .macro startSPCExecM ; startAddr
	rep     #XY_8BIT
	ldx     #\1
	jsr     StartSPCExec
 .endm
 
 
 .macro waitForAudio0M
 	sta	spcMirrorVal
 	-: 	cmp REG_APUI00
 	bne 	-
 .endm
 
 
 
 LoadSPC:
  	; Make sure NMI and IRQ are off
 	stz     REG_NMI_TIMEN   
 	sei             	
 
 	sta	spcSongNr
 	
 	; Make sure echo is off
 	sep	#A_8BIT
 	lda	#$7d		; Register $7d (EDL)
 	sta.l	$7f0100
 	lda	#$00		
 	sta.l	$7f0101
 	sendMusicBlockM $7f, $0100, $00f2, $0002 	
 	sep	#A_8BIT
 	lda	#$6c		; Register $6c (FLG)
 	sta.l	$7f0100
 	lda	#$20		; Bit 5 on (~ECEN)	
 	sta.l	$7f0101
 	sendMusicBlockM $7f, $0100, $00f2, $0002
 	
  	; Initialize DSP registers, except FLG, EDL, KON and KOF
 	jsr     InitDSP

	; Copy the SPC RAM dump to SNES RAM
 	jsr     CopySPCMemoryToRam
 
 	; Now we try to find a good place to inject our init code on the SPC side
 	;========================================================================
 	rep	#XY_8BIT
 	ldx	#SPC_DEFAULT_INIT_ADDRESS
 	stx	spcExecAddr
 	
 	; Check if we've got a non-zero EDL. In that case we use ESA*$100 + $200 as the base
 	; address for our init code.
 	sep	#A_8BIT
 	lda	SPC_REG_ADDR+$407d	; EDL
 	beq	+			
 	lda	SPC_REG_ADDR+$406d	; ESA
	clc
	adc	#2
 	xba
 	lda	#0
 	rep	#A_8BIT
 	tax				; X = ESA*$100 + $200
 	stx	spcExecAddr
 	jmp	addr_search_done
 	+:
 	
 	; Search for a free chunk of RAM somewhere in the range $0100..$ff9f
 	sep	#A_8BIT
 	ldx	#$100
 	search_free_ram:
		cpx	#$ff9f
		bcs	addr_search_done	; Found no free RAM. Give up and use the default address
		lda	#0
		sta	spcScanLen	
		search_free_ram_inner:
			lda.l	$7f0000,x
			cmp	spcScanVal
			bne	+			; No match?
			cmp	#$00
			beq	scan_val_ok
			cmp	#$ff
			bne	scan_next_row
			scan_val_ok:
			inc	spcScanLen
			lda	spcScanLen
			cmp	#($0C+SPC_INIT_CODE_LENGTH)
			beq	found_free_ram
			inx
			jmp	search_free_ram_inner
			+:
			xba
			lda	spcScanLen
			beq	+
			scan_next_row:
			rep	#A_8BIT
			txa
			clc
			adc	#$0010
			and	#$FFF0
			tax
			sep	#A_8BIT
			jmp	search_free_ram
			+:
			xba
			sta	spcScanVal
			inc	spcScanLen
			inx
			jmp	search_free_ram_inner
	found_free_ram:
	rep	#A_8BIT
	txa
	sec
	sbc	#($0B+SPC_INIT_CODE_LENGTH)
	tax
	sep	#A_8BIT
	stx	spcExecAddr
 
 	addr_search_done:
  	;========================================================================
  	
  	;ldx	#$01bb
  	;stx	spcExecAddr
  	
	; Copy fastloader to SNES RAM
	rep	#XY_8BIT
	sep	#A_8BIT
	ldx	#(SPC_FASL_LENGTH-2)
	-:
		lda.l	spc700_fasl_code,x
		sta.l	$7f0000,x
		dex
		bpl	-
	lda.l   SPC_REG_ADDR+$405c
	sta.l	$7f000b
	lda.l   SPC_REG_ADDR+$404c
	sta.l	$7f002d
	lda	spcExecAddr
	sta.l	$7f0030
	lda	spcExecAddr+1
	sta.l	$7f0031
	
	; Send the fastloader to SPC RAM
	sendMusicBlockM $7f, $0000, $0002, SPC_FASL_LENGTH
	
	; Start executing the fastloader
	startSPCExecM $0002
	
  	; Build code to initialize registers.
	jsr     MakeSPCInitCode

	; Upload the SPC data to $00f8..$ffff
	sep	#A_8BIT
	ldx	#$00f8
  	send_by_fasl:
		lda.l	$7f0000,x
		sta	REG_APUI01
		lda.l	$7f0001,x
		sta	REG_APUI02
		txa
		sta	REG_APUI00
		waitForAudio0M
		inx
		inx
		bne	send_by_fasl
	
	; > The SPC should be executing our initialization code now <

 	phb			; Save DBR
 	lda 	spcSongNr
 	asl	a
 	clc
 	adc	#SPC_DATA_BANK
 	pha
 	plb		
	ldx	#0
	copy_spc_page0:
		lda.w	$8000,x	; Read from ROM
		sta	REG_APUI01
		txa
		sta	REG_APUI00
		waitForAudio0M
		inx
		cpx	#$f0
		bne	copy_spc_page0
	lda	#$0a
	sta	REG_APUI01
	lda	#$f0
	sta	REG_APUI00
	waitForAudio0M
	lda.w	$80f1
	and	#7
	sta	REG_APUI01
	lda	#$f1
	sta	REG_APUI00
	waitForAudio0M
	plb			; Restore DBR
	
	; Write the init values for the IO ports
	lda.l	$7f00f7
	sta	REG_APUI03
	lda.l	$7f00f6
	sta	REG_APUI02
	lda.l	$7f00f4
	sta	REG_APUI00
	lda.l	$7f00f5
	sta	REG_APUI01
	
 	rts
  
 	
  
  CopySPCMemoryToRam:
 	; Copy music data from ROM to RAM, from the end backwards.
 	rep	#XY_8BIT        ; xy in 16-bit mode.
 	sep	#A_8BIT
 	ldx.w 	#$7fff          ; Set counter to 32k-1.
 
 	phb			; Save DBR
 	lda 	spcSongNr
 	asl	a
 	clc
 	adc	#SPC_DATA_BANK
 	pha
 	plb			; Set DBR to spcSongNr*2 + SPC_DATA_BANK
 -:  	lda.w 	$8000,x     	; Copy byte from first music bank.
 	sta.l 	$7f0000,x
 	dex
 	bpl 	-
 
 	lda	spcSongNr
 	asl	a
 	clc
 	adc	#(SPC_DATA_BANK+1)
 	pha
 	plb			; Set DBR to spcSongNr*2 + SPC_DATA_BANK + 1
 	ldx.w 	#$7fff          ; Set counter to 32k-1.
 -:
 	lda.w 	$8000,x     	; Copy byte from second music bank.
 	sta.l 	$7f8000,x
 	dex
 	bpl 	-
 	
 	plb			; restore DBR
 
	rts


; Loads the DSP init values in reverse order
 InitDSP:
	rep     #XY_8BIT	; xy in 16-bit mode
	lda	spcSongNr

	rep	#A_8BIT		; 16-bit accum
	xba
	lda	#0		; Clear high byte
	xba
	asl	a
	asl	a
	asl	a
	asl	a
	asl	a
	asl	a
	asl	a
	clc
	adc	#$007F
	tax			; x = spcSongNr*128 + 127
	sep	#A_8BIT		; 8-bit accum
	
	ldy	#$007F		; Reset DSP address counter.
-:
	sep     #A_8BIT
	tya                   	; Write DSP address register byte.
	sta     $7f0100            
	lda.l   SPC_REG_ADDR+$4000,x     	
	sta     $7f0101         ; Write DSP data register byte.    
	phx                   	; Save x on the stack.
	phy

	cpy	#$006c
	beq	skip_dsp_write
	cpy	#$007d
	beq	skip_dsp_write
	cpy	#$004c
	beq	skip_dsp_write
	cpy	#$005c
	bne	+
	lda	#$ff
	sta	$7f0101
	+:
	
	; Send the address and data bytes to the DSP memory-mapped registers.
	sendMusicBlockM $7f, $0100, $00f2, $0002

	skip_dsp_write:
	
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	
	rep     #XY_8BIT            ; Restore x.
	ply
	plx

	; Loop if we haven't done 128 registers yet.
	dex
	dey
	cpy     #$FFFF
	bne     -
	rts
	

 MakeSPCInitCode:
     ; Constructs SPC700 code to restore the remaining SPC state and start
     ; execution.
 
  	rep     #A_8BIT
 	lda	#0
 	ldx	#0			; Make sure A and X are both clear
 	rep	#XY_8BIT

  	ldy	spcExecAddr
 	
	sep     #A_8BIT

	lda	spcSongNr
	asl	a
	asl	a
	asl	a
	tax				; x = spcSongNr * 8

	phb				; Save DBR
	lda	#$7f
	pha
	plb				; Set DBR=$7f (RAM)
	
	; Write code to set s.
	lda     #$cd        		; mov x,#imm
	sta.w   $0000,y
	iny
	lda.l   SPC_REG_ADDR+6,x  	; x init value	
	sta.w   $0000,y
	iny
	lda     #$bd        		; mov sp,x
	sta.w   $0000,y
	iny

	; Write code to push psw
	lda     #$cd        		; mov x,#imm
	sta.w   $0000,y
	iny
	lda.l   SPC_REG_ADDR+5,x   	; psw init value
	sta.w   $0000,y
	iny
	lda     #$4d       		; push x
	sta.w   $0000,y
	iny

	phx				; Save X
	ldx	#0
	-:
	lda.l	spc700_load_first_page_code,x
	sta.w	$0000,y			; Store in SNES RAM
	iny
	inx
	cpx	#15
	bne	-
	plx				; Restore X

	; Write code to set DSP reg $7d (EDL)
	lda	#$8f			; mov dp,#imm
	sta.w   $0000,y
	iny
	lda	#$7d
	sta.w   $0000,y
	iny
	lda	#$f2			; DSP addr
	sta.w   $0000,y
	iny
	lda	#$8f			; mov dp,#imm
	sta.w   $0000,y
	iny
	lda.l   SPC_REG_ADDR+$407d
	sta.w   $0000,y
	iny
	lda	#$f3			; DSP data
	sta.w   $0000,y
	iny
	
	; Write code to set a.
	lda     #$e8        		; mov a,#imm
	sta.w   $0000,y
	iny
	lda.l   SPC_REG_ADDR+2,x 
	sta.w	$0000,y
	iny

	; Write code to set x.
	lda     #$cd       		; mov x,#imm
	sta.w   $0000,y
	iny
	lda.l   SPC_REG_ADDR+3,x 
	sta.w   $0000,y
	iny

	; Write code to set y.
	lda     #$8d        		; mov y,#imm
	sta.w   $0000,y
	iny
	lda.l   SPC_REG_ADDR+4,x 
	sta.w   $0000,y
	iny

	; Write code to set DSP reg $6c (FLG)
	lda	#$8f			; mov dp,#imm
	sta.w   $0000,y
	iny
	lda	#$6c
	sta.w   $0000,y
	iny
	lda	#$f2			; DSP addr
	sta.w   $0000,y
	iny
	lda	#$8f			; mov dp,#imm
	sta.w   $0000,y
	iny
	lda.l   SPC_REG_ADDR+$406c
	sta.w   $0000,y
	iny
	lda	#$f3			; DSP data
	sta.w   $0000,y
	iny
	
	; Write code to pull psw.
	lda     #$8e        		; pop psw
	sta.w   $0000,y
	iny

	; Write code to jump.
	lda     #$5f        		; jmp labs
	sta.w   $0000,y
	iny
	rep     #A_8BIT
	lda.l   SPC_REG_ADDR,x  
	sep     #A_8BIT
	sta.w   $0000,y
	iny
	xba
	sta.w   $0000,y
	iny

	plb				; Restore DBR
	rts


; spcSourceAddr - source address
; x - dest address
; y - count
 CopyBlockToSPC:
 	rep	#XY_8BIT
 	
	; Wait until audio0 is $aa
	sep     #A_8BIT
	lda     #$aa
	waitForAudio0M

	stx     REG_APUI02		; Write it to APU Port2 as well
	
	; Transfer count to x.
	phy
	plx

 	; Send $01cc to AUDIO0 and wait for echo.
	lda	#$01
	sta     REG_APUI01
	lda	#$cc
	sta     REG_APUI00
	waitForAudio0M

	sep     #A_8BIT

	; Zero counter.
	ldy     #$0000
 CopyBlockToSPC_loop:
	lda     [spcSourceAddr],y

	sta	REG_APUI01
	
	; Counter -> A
	tya

	sta	REG_APUI00

	; Wait for counter to echo back.
	waitForAudio0M

	; Update counter and number of bytes left to send.
	iny
	dex
	bne     CopyBlockToSPC_loop

 	sep	#A_8BIT
 	
	; Send the start of IPL ROM send routine as starting address.
	ldx     #$ffc9
	stx     REG_APUI02
	
	; Tell the SPC we're done transfering for now
	lda     #0
	sta	REG_APUI01
	lda	spcMirrorVal	; This value is filled out by waitForAudio0M
	clc
	adc	#$02		
	sta	REG_APUI00

	; Wait for counter to echo back.
	waitForAudio0M

	rep     #A_8BIT
	
	rts

 
 
; Starting address is in x.
 StartSPCExec:
	; Wait until audio0 is $aa
	sep     #A_8BIT
	lda     #$aa
	waitForAudio0M

	; Send the destination address to AUDIO2.
	stx     REG_APUI02

	; Send $00cc to AUDIO0 and wait for echo.
	lda     #$00
	sta     REG_APUI01
	lda     #$cc
	sta     REG_APUI00
	waitForAudio0M

	rts
	

; Code for transferring the first page of SPC RAM (up to $00f1)
spc700_load_first_page_code:
 .db $cd, $00	; mov   x,#0
 .db $3e, $f4  	; -: cmp   x,$f4
 .db $d0, $fc 	;    bne   -
 .db $e4, $f5  	;    mov   a,$f5
 .db $d8, $f4  	;    mov   $f4,x
 .db $af 	;    mov   (x)+,a
 .db $c8, $f2	;    cmp   x,#$f2
 .db $d0, $f3	;    bne   -
spc700_load_first_page_code_end: 
 ; 15 bytes
 ; minimum 22 cycles per byte transfered


; Code for transferring data to SPC RAM at $00f8..$ffff
spc700_fasl_code:
 .db $cd, $00		; 0002 mov x,#0
 .db $8d, $f8		; 0004 mov y,#$f8
 .db $8f, $00, $f1	; 0006 mov $f1, #0
 .db $8f, $5c, $f2	; 0009 mov $f2, #$5c 
 .db $8f, $00, $f3	; 000c mov $f2, #$xx  	(the value is filled in later)
 .db $7e, $f4     	; 000f -: cmp   y,$f4  
 .db $d0, $fc     	; 0011    bne   -
 .db $e4, $f5     	; 0013    mov   a,$f5
 .db $d6, $00, $00	; 0015    mov   $0000+y,a
 .db $cb, $f4     	; 0018    mov   $f4,y
 .db $e4, $f6     	; 001a    mov   a,$f6
 .db $d6, $01, $00     	; 001c    mov   $0001+y,a
 .db $fc        	; 001f    inc   y
 .db $fc        	; 0020    inc   y
 .db $d0, $ec     	; 0021    bne   - 
 .db $ac, $17, $00     	; 0023    inc   $0017
 .db $ac, $1e, $00     	; 0026    inc   $001e
 .db $d0, $e4		; 0029    bne   -
 .db $8f, $4c, $f2	; 002b mov   $f2, #$4c 
 .db $8f, $00, $f3	; 002e mov   $f2, #$xx 	(the value is filled in later)
 .db $5f, $00, $00	; 0031 jmp   $xxxx   	(this address is filled in later)
spc700_fasl_code_end:
 ; 50 bytes
 ; minimum 17.55 cycles per byte transfered
 
