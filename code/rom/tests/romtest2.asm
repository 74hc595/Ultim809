; vim:noet:sw=8:ts=8:ai:syn=as6809
; Matt Sarnoff (msarnoff.org/6809) - April 18, 2011

; ROM test 2 - tests UART
; Does not use any RAM!
; Connect to PC/terminal, 38400 baud, 8 data bits, 1 stop bit, no parity.
;
; Change LED color by sending 'r' (red), 'g' (green), 'y' (yellow) or 'o' (off).

	.include "../hardware.inc"

	.area	_CODE(ABS)
	.org	0xE000
MAIN:
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
		
; print instructions
		ldx	#hello
		ldb	#LED_OFF
		bra	ledprintstr

; main loop
loop:		ldb	#0b00000001	;receive data ready?
1$:		bitb	UART_LSR
		beq	1$		;if not, wait
		ldb	UART_RHR	;get the character
		cmpb	#'r
		beq	red
		cmpb	#'y
		beq	yellow
		cmpb	#'g
		beq	green
		cmpb	#'o
		beq	off
		bra	loop

red:		ldx	#redstr
		ldb	#LED_RED
		bra	ledprintstr

yellow:		ldx	#yellowstr
		ldb	#LED_YELLOW
		bra	ledprintstr

green:		ldx	#greenstr
		ldb	#LED_GREEN
		bra	ledprintstr

off:		ldx	#offstr
		ldb	#LED_OFF
		;fall through

; print string in X and set LED to color in B, then return to main loop
ledprintstr:	stb	UART_MCR	;set LED color
1$:		ldb	,x+
		beq	loop
		lda	#0b00100000	;transmit holding register empty?
2$:		bita	UART_LSR
		beq	2$		;if not, wait
		stb	UART_THR	;send character
		bra	1$

; strings
hello:		.ascii	"Hello World!"
		.fcb	0x0d,0x0a
		.ascii	"Type r, y, g, or o to change LED color"
		.fcb	0x0d,0x0a,0

redstr:		.ascii	"Red."
		.fcb	0x0d,0x0a,0
yellowstr:	.ascii	"Yellow."
		.fcb	0x0d,0x0a,0
greenstr:	.ascii	"Green."
		.fcb	0x0d,0x0a,0
offstr:		.ascii	"Off."
		.fcb	0x0d,0x0a,0

	.org	0xFFF2
SWI3:		.fdb	MAIN
SWI2:		.fdb	MAIN
FIRQ:		.fdb	MAIN
IRQ:		.fdb	MAIN
SWI:		.fdb	MAIN
NMI:		.fdb	MAIN
RESET:		.fdb	MAIN
