; vim:noet:sw=8:ts=8:ai:syn=as6809
; Matt Sarnoff (msarnoff.org/6809) - April 18, 2011

; ROM test 3 - tests RAM and bank switching
; Connect to PC/terminal, 38400 baud, 8 data bits, 1 stop bit, no parity.
;
; Counts the number of 16K pages available and prints the total RAM size,
; in kilobytes, on the serial console.

	.include "../hardware.inc"

; zero page variables
NUMKB_H		.equ	0x01		;memory size in KB, encoded as BCD
NUMKB_L		.equ	0x02

	.area	_CODE(ABS)
	.org	0xE000
MAIN:		lds	#0x0100		;hooray, we can use a stack
		clra
		tfr	a,dp		;set direct page register
		lda	#0xFF		;set up bank register (outputs)
		sta	VIA_DDRA

; initialize UART
		ldx	#B38400		;38400 baud
		clr	UART_FCR	;disable FIFO
		clr	UART_IER	;interrupts off
		lda	#0b00001100	;clear modem controls, LED off
		sta	UART_MCR
		lda	#0b10000011	;8 data bits, no parity, 1 stop bit,
		sta	UART_LCR	; enable divisor latch
		stx	UART_DLL	;store divisor
		anda	#0b01111111	;disable divisor latch
		sta	UART_LCR

; initialize variables
		ldd	#0x0016		;assume at least one page
		std	*NUMKB_H

; count number of pages
; first, clear starting byte of all possible 16K pages
1$:		sta	PAGE
		clr	XRAMSTART
		inca
		bne	1$
; set starting byte of page 0 to magic value (all others will be 0)
		clr	PAGE
		lda	#0xA5
		sta	0x0000
; iterate over all pages until we wrap around
; at that point, the value in 0x8000 should be the magic value
countpages:	inc	PAGE
		lda	#0xA5
		cmpa	XRAMSTART
		beq	done
		lda	#0x16		;add 16 to kilobyte count
		adda	*NUMKB_L
		daa
		sta	*NUMKB_L
		lda	#0
		adca	*NUMKB_H
		daa
		sta	*NUMKB_H
		bra	countpages

; print memory size
done:		ldd	*NUMKB_H
		bsr	OUTHEXW
		ldx	#str
		bsr	OUTSTR
loop:		sync			;loop forever
		jmp	loop


; print word in D as hexadecimal
OUTHEXW:	pshs	b		;save lsb
		tfr	a,b
		bsr	OUTHEXB		;print msb
		puls	b		;restore lsb
		;fall through and print lsb

; print byte in B as hexadecimal
OUTHEXB:	pshs	b		;save for least significant digit
		lsrb			;get most significant digit
		lsrb
		lsrb
		lsrb
		bsr	OUTHEX		;print most significant digit
		puls	b		;restore least significant digit
		;fall through and print least significant digit

; print hexadecimal nibble
OUTHEX:		andb	#0b00001111	;least significant digit only
		orb	#'0
		cmpb	#'9+1		;decimal digit?
		blo	UART_OUTCH	;if so, print it
		addb	#7		;no, add offset
		;fall through to print character

; print character in B
UART_OUTCH:	lda	#0b00100000	;transmit holding register empty?
1$:		bita	UART_LSR
		beq	1$		;if not, wait
		stb	UART_THR	;send character
		rts

; print string in X
OUTSTR:		ldb	,x+
		beq	osdone
		bsr	UART_OUTCH
		bra	OUTSTR
osdone:		rts


; strings
str:		.ascii	"KB RAM available."
		.fcb	0x0d,0x0a,0


	.org	0xFFF2
SWI3:		.fdb	MAIN
SWI2:		.fdb	MAIN
FIRQ:		.fdb	MAIN
IRQ:		.fdb	MAIN
SWI:		.fdb	MAIN
NMI:		.fdb	MAIN
RESET:		.fdb	MAIN
