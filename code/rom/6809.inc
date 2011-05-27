; vim:noet:sw=8:ts=8:ai:syn=as6809
	.ifndef	_6809_INC_
	.define _6809_INC_

;************ Hardware addresses ************
	.include "hardware.inc"

;************ Zero page variables ************
.globl	SWIVEC		;SWI vector
.globl	SWI2VEC		;SWI2 vector
.globl	SWI3VEC		;SWI3 vector
.globl	NMIVEC		;NMI vector
.globl	IRQVEC		;IRQ vector
.globl	FIRQVEC		;FIRQ vector
.globl	OUTCH		;pointer to character output function
.globl	INCH		;pointer to character input function
.globl	NUMRAMPAGES	;number of 16K pages
.globl	RAM_KB_BCD	;RAM size in KB (as binary coded decimal)
.globl	L		;32-bit register
.globl	LL		;high 16 bits
.globl	LH		;low 16 bits
.globl	COUNT		;16-bit temporary
.globl	CURSORPOS	;text console cursor position
.globl	KEYSTATE	;keyboard modifiers
.globl	KBD_SAVE	;used to save registers in the interrupt handler
.globl	KBD_BITSLEFT	;number of bits left to read
.globl	KBD_SCANCODE	;scancode being received

; The scancode buffer is 16 bytes and is aligned on a 16-byte boundary
; Even though the head and tail pointers are 2 bytes, we can get away with
; manipulating only the low bytes.
.globl	KBD_HEADPTR	;pointer to the head of the buffer
.globl	KBD_HEADPTR_L
.globl	KBD_TAILPTR	;pointer to the tail of the buffer
.globl	KBD_TAILPTR_L
.globl	KBD_BUFSTART	;start of the buffer (16-byte aligned)
.globl	KBD_BUFEND	;end of the buffer
.globl	KBD_BUFMASK

	.endif
