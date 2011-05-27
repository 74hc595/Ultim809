; vim:noet:sw=8:ts=8:ai:syn=as6809
; Matt Sarnoff (msarnoff.org/6809) - May 26, 2010

;************ 16C550 UART routines ************
		
;;; initialize the UART (8 data bits, no parity, 1 stop bit)
;;; arguments:	baud rate divisor in X (little-endian)
;;; returns:	none
;;; destroys:	A
;;; Use one of the B* baud rate constants, they are already byte-swapped.
UART_INIT::	clr	UART_FCR	;disable FIFO
		clr	UART_IER	;interrupts off
		lda	#0b00001100	;clear modem controls, LED off
		sta	UART_MCR
		lda	#0b10000011	;8 data bits, no parity, 1 stop bit,
		sta	UART_LCR	; enable divisor latch
		stx	UART_DLL	;store divisor
		anda	#0b01111111	;disable divisor latch
		sta	UART_LCR
		rts

;;; install input/output handlers
;;; arguments:	none
;;; returns:	none
;;; destroys:	D
UART_IO::	ldd	#UART_OUTCH
		std	*OUTCH
		ldd	#UART_INCH
		std	*INCH
		rts

	.if 0
;;; set the UART baud rate
;;; arguments:	baud rate divisor in D, MSB first
;;; returns:	none
;;; destroys:	A,B
UART_SETBAUD::	pshs	d		;save divisor
		lda	UART_LCR	;enable divisor latch
		ora	#0b10000000
		sta	UART_LCR
		puls	d		;restore divisor
		exg	a,b		;make little-endian
		std	UART_DLL
		lda	UART_LCR	;disable divisor latch
		anda	#0b01111111
		sta	UART_LCR
		rts
	.endif

;;; set the tricolor status LED (connected to UART pins OP1, OP2)
;;; arguments:	color value in B (LED_RED, LED_YELLOW, LED_GREEN, or LED_OFF)
;;; returns:	none
;;; destroys:	none
UART_SETLED::	stb	UART_MCR
		rts

;;; send a character over the UART
;;; arguments:	character in B
;;; returns:	none
;;; destroys:	none
UART_OUTCH::	pshs	b		;reuse b for status check
		ldb	#0b00100000	;transmit holding register empty?	
1$:		bitb	UART_LSR
		beq	1$		;if not, wait
		puls	b
		;fall through

;;; send a character over the UART without waiting
;;; arguments:	character in B
;;; returns:	none
;;; destroys:	none
UART_OUTCH_NW::	stb	UART_THR
		rts

;;; waits for a character to be received from the UART and returns it in B
;;; arguments:	none
;;; returns:	character in B
;;; destroys:	B
UART_INCH::	ldb	#0b00000001	;receive data ready?
1$:		bitb	UART_LSR
		beq	1$		;if not, wait
		ldb	UART_RHR	;get the character and return
		rts

