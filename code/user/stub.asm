; vim:noet:sw=8:ts=8:ai:syn=as6809
; Ultim809 user program template

	.nlist
	.include "../../rom/6809.inc"
	.include "../../rom/rom06.inc"
	.list

; VRAM addresses (for Graphics I)
SPRPATTABLE	.equ	0x0000
PATTABLE	.equ	0x0800
SPRATTABLE	.equ	0x1000
NAMETABLE	.equ	0x1400
COLORTABLE	.equ	0x2000

; Parameters

;------------------------------------------------------------------------------
; variables
;------------------------------------------------------------------------------

; variables in direct page
VARSTART	.equ	0x80

;------------------------------------------------------------------------------
; setup
;------------------------------------------------------------------------------
	.area	_CODE(ABS)
	.org	USERPROG_ORG
		lds	#RAMEND+1	;set up stack pointer
		ldd	#VBLANK		;set up interrupt vector
		std	IRQVEC
		jsr	VDP_CLEAR	;clear VRAM
		ldx	#vdp_regs	;initialize VDP registers
		jsr	VDP_SET_REGS

; set up the pattern table
; set up the color table
; set up variables
; set up sound

; enable interrupts
		andcc	#0b11101111

; turn on the display, enable vertical blanking interrupt
		ldd	#0xE081		;set bits 6 and 5 of register 1
		sta	VDP_REG
		stb	VDP_REG
		jmp	loop


;------------------------------------------------------------------------------
; logic update routine
;------------------------------------------------------------------------------
loop:	
; read controllers/keyboard
; update logic
; update sound
		sync
		jmp	loop


;------------------------------------------------------------------------------
; vertical blanking interrupt handler
;------------------------------------------------------------------------------
VBLANK:		lda	VDP_REG		;read status, clear interrupt flag
; update VRAM
		rti		
	

;------------------------------------------------------------------------------
; subroutines
;------------------------------------------------------------------------------


;------------------------------------------------------------------------------
; includes
;------------------------------------------------------------------------------

	;.include "../include/ym2149.asm"
	;etc.

;------------------------------------------------------------------------------
; static data
;------------------------------------------------------------------------------

; VDP register values
vdp_regs:	.fcb	0x00	;Graphics I
		.fcb	0x80	;Graphics I, 16K, display off, no sprites
		.fcb	NAMETABLE/0x0400
		.fcb	COLORTABLE/0x0040
		.fcb	PATTABLE/0x0800
		.fcb	SPRATTABLE/0x0080
		.fcb	SPRPATTABLE/0x0800
		.fcb	0x01	;black background

; tables, graphics, etc.


;------------------------------------------------------------------------------
; RAM data structures
;------------------------------------------------------------------------------

