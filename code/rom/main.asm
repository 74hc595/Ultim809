; vim:noet:sw=8:ts=8:ai:syn=as6809
; Matt Sarnoff (msarnoff.org/6809) - May 26, 2010

	.area	_CODE(ABS)

	.nlist
	.include "6809.inc"
	.list

;************ Customizable vectors in zero page ************
	.org	SYSRAM
SWI3VEC:	.rmb	2		;SWI3 vector
SWI2VEC:	.rmb	2		;SWI2 vector
FIRQVEC:	.rmb	2		;FIRQ vector
IRQVEC:		.rmb	2		;IRQ vector
SWIVEC:		.rmb	2		;SWI vector
NMIVEC:		.rmb	2		;NMI vector
OUTCH:		.rmb	2		;pointer to character output function
INCH:		.rmb	2		;pointer to character input function

;************ Zero page system variables ************
NUMRAMPAGES:	.rmb	1		;number of 16K pages
RAM_KB_BCD:	.rmb	2		;RAM size in BCD kilobytes
L:		.rmb	4
LH		.equ	L
LL		.equ	L+2
CURSORPOS:	.rmb	2
KEYSTATE:	.rmb	1
KBD_SAVE:	.rmb	1
KBD_BITSLEFT:	.rmb	1
KBD_SCANCODE:	.rmb	1

	.org	(SYSRAM-2)+0x20
KBD_BUFSTART:	.rmb	16
KBD_BUFEND	.equ	.-1
KBD_BUFMASK	.equ	0b11101111

KBD_HEADPTR:	.rmb	1
KBD_HEADPTR_L:	.rmb	1
KBD_TAILPTR:	.rmb	1
KBD_TAILPTR_L:	.rmb	1


;COUNT:		.rmb	2		;16-bit temporary

;************ Main routine ************
	.org	ROMSTART
MAIN:		lds	#ROMSTKSTART+1	;set up ROM stack pointer
		lda	#ROMDP		;set up direct page register
		tfr	a,dp

; set up VIA and memory banking, calculate RAM size
		lda	#0xFF		;port A (page register) all outputs
		sta	VIA_DDRA
		bsr	CALCRAMSIZE
		lda	#2		;bank in ram page 2
		sta	PAGE

; set up serial port
		ldx	#B38400		;set UART to 38400 baud
		bsr	UART_INIT	;initialize UART

; set up I/O functions
		bsr	UART_IO

; load the interrupt vectors
		ldd	#STARTUP	;SWI2 returns to startup screen
		std	*SWI2VEC
		ldd	#DUMMY_VECTOR
		std	*SWI3VEC	;SWI3 does nothing
		std	*IRQVEC		;IRQ does nothing
		std	*FIRQVEC	;FIRQ does nothing
		std	*SWIVEC

		ldd	#REMOTEMONITOR
		std	*NMIVEC

; start
		;jmp	STARTUP
		jmp	0x0100
		;swi2			;show the startup screen

; should not get here! loop forever
done:		bra	.		;wait

;************ Include files ************

		.include "memcheck.asm"
		.include "uart.asm"
		.include "output.asm"
		.include "tms9918.asm"
		.include "kbd6522.asm"
		.include "keydecode.asm"
		.include "console.asm"
		.include "startup.asm"
		.include "remote.asm"
		;.include "monitor.asm"

;************ Strings ************
	.org 0xFF8B
ultim809:	.asciz	"ULTIM809"
version:	.asciz	"ROM v0.6, 10 May 2011"
ramavail:	.asciz	"KB RAM available"
monitorinst:	.asciz	"Press INTERRUPT for monitor"

;************ Interrupt handlers ************
SWI3_HANDLER:	jmp	[SWI3VEC]
SWI2_HANDLER:	jmp	[SWI2VEC]
FIRQ_HANDLER:	jmp	[FIRQVEC]
IRQ_HANDLER:	jmp	[IRQVEC]
SWI_HANDLER:	jmp	[SWIVEC]
NMI_HANDLER:	jmp	[NMIVEC]

; dummy interrupt handler does nothing
DUMMY_VECTOR::	rti

;************ Interrupt vectors **********
	.org 0xFFF0
		.fdb	0x0000	;reserved
	.org 0xFFF2
		.fdb	SWI3_HANDLER
	.org 0xFFF4
		.fdb	SWI2_HANDLER
	.org 0xFFF6
		.fdb	FIRQ_HANDLER
	.org 0xFFF8
		.fdb	IRQ_HANDLER
	.org 0xFFFA
		.fdb	SWI_HANDLER
	.org 0xFFFC
		.fdb	NMI_HANDLER
	.org 0xFFFE
RESET:		.fdb	MAIN
