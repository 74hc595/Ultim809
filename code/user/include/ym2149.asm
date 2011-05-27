; vim:noet:sw=8:ts=8:ai:syn=as6809
; Matt Sarnoff (msarnoff.org/6809) - November 5, 2010
;
;************ YM2149/AY-3-8910 Programmable Sound Generator ************
;
; Assuming a 2 MHz master clock:
;
; Tone generator frequency = 2000000 / (16 * T)
;   where T is the 12-bit value in 0x01-0x00, 0x03-0x02, or 0x05-0x04
;   min (T=4095):  30.525 Hz
;   max (T=1):     125000 Hz
; given F in Hz, T = 125000 / F
;
; Noise generator frequency = 2000000 / (16 * N)
;   where N is the 5-bit value in 0x06
;   min (N=31):    4032.3 Hz
;   max (N=1):     125000 Hz
;
; Envelope frequency = 2000000 / (256 * E)
;   where E is the 16-bit value in 0x0C-0x0B
;   min (E=65535): 0.1192 Hz
;   max (E=1):     7812.5 Hz
 
;;; silence the sound generator
;;; arguments:	none
;;; returns:	none
;;; destroys:	A,B
PSG_SILENCE::	ldd	#(PSG_CTRL<<8)|TONE_NONE|NOISE_NONE
		std	PSG		;write address (in A) then data (in B)
		rts


;;; write to a PSG register
;;; arguments:	register address (0x00-0x0F) in A
;;;		data in B
;;; returns:	none
;;; destroys:	none
PSG_WRITE::	std	PSG
		rts


;;; read from a PSG register
;;; argments:	register address (0x00-0x0F) in A
;;; returns:	register value in A
;;; destroys:	none
PSG_READ::	sta	PSG
		lda	PSG
		rts


;;; write 2-byte value to registers 0x00-0x01 (tone generator A frequency)
;;; arguments:	value in D (big-endian)
;;; returns:	none
;;; destroys:	A,B
PSG_SET_AFREQ::	pshs	a
		lda	#PSG_A_FREQL	;address 0
		std	PSG		;write address 0 followed by data LSB
		inca			;address 1
		puls	b		;get data MSB
		std	PSG		;write address 1 followed by data MSB
		rts


;;; write 2-byte value to registers 0x02-0x03 (tone generator B frequency)
;;; arguments:	value in D (big-endian)
;;; returns:	none
;;; destroys:	A,B
PSG_SET_BFREQ::	pshs	a
		lda	#PSG_B_FREQL
		std	PSG
		inca
		puls	b
		std	PSG
		rts


;;; write 2-byte value to registers 0x04-0x05 (tone generator C frequency)
;;; arguments:	value in D (big-endian)
;;; returns:	none
;;; destroys:	A,B
PSG_SET_CFREQ::	pshs	a
		lda	#PSG_C_FREQL
		std	PSG
		inca
		puls	b
		std	PSG
		rts


;;; write 2-byte value to registers 0x0B-0x0C (envelope frequency)
;;; arguments:	value in D (big-endian)
;;; returns:	none
;;; destroys	A,B
PSG_SET_EFREQ::	pshs	a
		lda	#PSG_ENV_FREQL
		std	PSG
		inca
		puls	b
		std	PSG
		rts


;;; read 1-button Atari joysticks
;;; arguments:	none
;;; returns:	controller 1 button state in A
;;;		controller 2 button state in B
;;; destroys:	none
;;;
;;; A 1 bit indicates a pressed button.
;;; On return, flags reflect controller 1 state.
READ_1BUTTON::	lda	CTLR_SET_SELECT	;make sure select line is high
		
		ldb	#PSG_IO_B
		stb	PSG_LATCH_ADDR
		ldb	PSG_READ_ADDR
		comb
		andb	#0b00011111	;controller 2 state in B

		lda	#PSG_IO_A
		sta	PSG_LATCH_ADDR
		lda	PSG_READ_ADDR
		coma
		anda	#0b00011111	;controller 1 state in A
		rts


;;; read 3-button Sega gamepads
;;; arguments:	none
;;; returns:	controller 1 button state in A
;;;		controller 2 button state in B
;;; destroys:	none
;;;
;;; A 1 bit indicates a pressed button.
;;; Flags are not set on return.
READ_3BUTTON::	leas	-2,s		;2 bytes for controller states
		lda	CTLR_CLR_SELECT	;read A and Start buttons
		lda	#PSG_IO_A	;read controller 1
		sta	PSG_LATCH_ADDR
		lda	PSG_READ_ADDR
		coma			;invert bits so 1 indicates press
		anda	#0b00110000
		lsla			;shift into bits 6 and 7
		lsla
		sta	,s
		lda	#PSG_IO_B	;read controller 2
		sta	PSG_LATCH_ADDR
		lda	PSG_READ_ADDR
		coma
		anda	#0b00110000
		lsla
		lsla
		sta	1,s

		lda	CTLR_SET_SELECT	;read up, down, left, right, B, C
		lda	#PSG_IO_A
		sta	PSG_LATCH_ADDR
		lda	PSG_READ_ADDR
		coma
		anda	#0b00111111
		ora	,s
		sta	,s
		lda	#PSG_IO_B
		sta	PSG_LATCH_ADDR
		lda	PSG_READ_ADDR
		coma
		anda	#0b00111111
		ora	1,s
		sta	1,s
		puls	a,b,pc		;return controller states in A and B

