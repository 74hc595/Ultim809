; vim:noet:sw=8:ts=8:ai:syn=as6809
; Matt Sarnoff (msarnoff.org/6809) - December 12, 2010

;************ Startup routine ************

STARTUP::	orcc	#0b01010000	;disable interrupts
		lds	#0x100	;restore stack and DP
		lda	#0
		tfr	a,dp
		lda	VBANK_LOWER	;select lower 16K of VRAM
		jsr	VDP_INITTEXT	;start text mode, display off
		jsr	VDP_TEXT_ON

; print strings and RAM count
		ldd	#VDP_OUTCH
		std	*OUTCH

		ldd	#VRAM|TEXT_NAMETABLE
		ldx	#ultim809
		ldu	#VDP_PRINTSTR
		jsr	,u		;print "ULTIM809"
		ldd	#VRAM|TEXT_NAMETABLE+40
		jsr	,u		;print ROM version
		ldd	#VRAM|TEXT_NAMETABLE+80
		stb	VDP_REG
		sta	VDP_REG
		ldd	*RAM_KB_BCD
		jsr	OUTBCDW		;print RAM size
		jsr	VDP_PRINTSTRC	;print "KB RAM available"
		ldd	#VRAM|TEXT_NAMETABLE+160
		jsr	,u		;print "Press INTERRUPT..."

; turn on display and set green LED
		ldb	#LED_GREEN
		jsr	UART_SETLED

; loop
		bra	.
