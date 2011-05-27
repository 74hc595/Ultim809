; vim:noet:sw=8:ts=8:ai:syn=as6809
; Matt Sarnoff (msarnoff.org/6809) - January 10, 2011
;
; Sega 3-button gamepad test program
; Controllers connected to ports A and B of the YM2149

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
		lda	CTLR_SET_SELECT	;make sure controller SELECT is set
		jsr	VDP_INITTEXT	;text mode

; print strings
		ldd	#NAMETABLE
		ldx	#titlestr	;print title string (advances X)
		jsr	VDP_PRINTSTR
		ldd	#NAMETABLE+80
		jsr	VDP_PRINTSTR	;print player 1 string
		ldd	#NAMETABLE+120
		jsr	VDP_PRINTSTR	;print player 2 string
		
; enable interrupts
		andcc	#0b11101111

; turn on the display, enable vertical blanking interrupt
		ldd	#0xF081		;set bits 6 and 5 of register 1
		sta	VDP_REG
		stb	VDP_REG
		bra	loop


;------------------------------------------------------------------------------
; logic update routine
;------------------------------------------------------------------------------
loop:		jsr	READ_3BUTTON	;read controllers
		sta	PAD1STATE
		stb	PAD2STATE

		sync
		jmp	loop


;------------------------------------------------------------------------------
; vertical blanking interrupt handler
;------------------------------------------------------------------------------
VBLANK:		lda	VDP_REG		;read status, clear interrupt flag

; print controller 1 state
		ldd	#(VRAM|NAMETABLE+90)
		stb	VDP_REG
		sta	VDP_REG
		lda	PAD1STATE
		bsr	DISPSTATE

; print controller 2 state
		ldd	#(VRAM|NAMETABLE+130)
		stb	VDP_REG
		sta	VDP_REG
		lda	PAD2STATE
		bsr	DISPSTATE

		rti


;------------------------------------------------------------------------------
; subroutines
;------------------------------------------------------------------------------

;;; display controller state (bits in A, 1 indicates button pressed)
DISPSTATE:	ldx	#btnsymbols
dispbtn:	ldb	,x+		;get symbol for this button
		beq	dispdone
		lsra			;read button bit
		bcs	pressed		;bit set? button pressed
		ldb	#'_		;bit clear? button not pressed
pressed:	stb	VDP_VRAM	;print character
		ldb	#0x20		;print space
		stb	VDP_VRAM
		bra	dispbtn
dispdone:	rts


;------------------------------------------------------------------------------
; includes
;------------------------------------------------------------------------------

	.include "../include/ym2149.asm"

;------------------------------------------------------------------------------
; static data
;------------------------------------------------------------------------------

titlestr:	.asciz	"Controller Test"
p1str:		.asciz	"Player 1:"
p2str:		.asciz	"Player 2:"
btnsymbols:	.fcb	0x03,0x04,0x05,0x06,'B,'C,'A,'S,0x00


;------------------------------------------------------------------------------
; variables
;------------------------------------------------------------------------------

PAD1STATE:	.rmb	1
PAD2STATE:	.rmb	1
