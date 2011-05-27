; vim:noet:sw=8:ts=8:ai:syn=as6809
; Matt Sarnoff (msarnoff.org/6809) - January 25, 2011
;
; PS/2 keyboard test program

	.nlist
	.include "../../rom/6809.inc"
	.include "../../rom/rom06.inc"
	.list

NAMETABLE	.equ	0x0000

	.area	_CODE(ABS)
	.org	USERPROG_ORG
;------------------------------------------------------------------------------
; setup
;------------------------------------------------------------------------------
		lds	#RAMEND+1	;set up stack pointer
		ldd	#VBLANK		;set up interrupt vector
		std	IRQVEC
		ldd	#VDP_OUTCH	;set up character output vector
		std	OUTCH
		jsr	VDP_INITTEXT	;text mode
		jsr	KBD_INIT	;initialize keyboard handler

; enable interrupts
		andcc	#0b11101111
		jsr	KBD_ENABLE	;enable keyboard interrupt


; turn on the display, enable vertical blanking interrupt
		ldd	#0xF081		;set bits 6 and 5 of register 1
		sta	VDP_REG
		stb	VDP_REG

; set up variables
		ldd	#VRAM|NAMETABLE
		std	CURSORPOS
		clr	KEYSTATE

;------------------------------------------------------------------------------
; logic update routine
;------------------------------------------------------------------------------
loop:		;sync
		jmp	loop


;------------------------------------------------------------------------------
; vertical blanking interrupt handler
;------------------------------------------------------------------------------
VBLANK:		lda	VDP_REG		;read status, clear interrupt flag
		
getcodes:	jsr	KBD_GETCODE	;get scancodes from buffer
		beq	nomorekeys	;stop if 0 received
		lda	KEYSTATE
		jsr	KBD_DECODE	;convert scancode to ASCII
		sta	KEYSTATE
		tstb
		beq	getcodes	;skip if 0 is returned
; display the character
		pshs	b
		ldd	CURSORPOS	;set cursor position
		stb	VDP_REG
		sta	VDP_REG
		addd	#1		;increment
		cmpd	#(VRAM|NAMETABLE+960)
		blo	dispchar	;check for overflow
		ldd	#VRAM|NAMETABLE	;if so, return cursor to top of screen
dispchar:	std	CURSORPOS
		puls	b
		stb	VDP_VRAM	;put the character on screen
		bra	getcodes
nomorekeys:	rti


;------------------------------------------------------------------------------
; subroutines
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
; includes
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
; static data
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
; variables
;------------------------------------------------------------------------------

