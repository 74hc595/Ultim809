; vim:noet:sw=8:ts=8:ai:syn=as6809
; Matt Sarnoff (msarnoff.org/6809) - April 18, 2011

; ROM test 1 - tests address decoding
; Does not use any RAM!

	.area	_CODE(ABS)
	.org	0xE000
MAIN:		
; test RAM, reads and writes
		ldx	#0
1$:		lda	,x
		sta	,x
		leax	0x400,x
		cmpx	#0xC000
		bne	1$

; test I/O and ROM, reads only
2$:		lda	,x
		leax	0x400,x
		bne	2$
		
; delay about a second
		ldx	#0
delay:		lbrn	.
		lbrn	.
		lbrn	.
		lbrn	.
		nop
		leax	-1,x
		bne	delay

; stop
		sync

	.org	0xFFF2
SWI3:		.fdb	MAIN
SWI2:		.fdb	MAIN
FIRQ:		.fdb	MAIN
IRQ:		.fdb	MAIN
SWI:		.fdb	MAIN
NMI:		.fdb	MAIN
RESET:		.fdb	MAIN
