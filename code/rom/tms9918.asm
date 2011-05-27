; vim:noet:sw=8:ts=8:ai:syn=as6809
; Matt Sarnoff (msarnoff.org/6809) - November 13, 2010
;
;************ TMS9918A/9928A/9929A Video Display Processor ************
;

TEXT_NAMETABLE	.equ	0x0000		;text mode VRAM addresses
TEXT_PATTABLE	.equ	0x0800

;;; clear all VDP memory
;;; arguments:	none
;;; returns:	none
;;; destroys:	A,B
VDP_CLEAR::	pshs	x
		ldd	#(VRAM|0x0000)	;write address, start at 0x0000
		stb	VDP_REG		;low byte first
		sta	VDP_REG		;then high byte
		ldx	#16384		;clear all 16K
		clra
		bra	fill_loop


;;; fill a portion of VDP memory with a byte
;;; arguments:	VRAM address should be set already
;;;		number of bytes to fill in X
;;;		byte value in A
;;; returns:	none
;;; destroys:	none
VDP_FILL::	pshs	x
fill_loop:	sta	VDP_VRAM
		leax	-1,x
		bne	fill_loop
		puls	x,pc		;restore X and return


;;; clear VRAM and initialize text mode
;;; arguments:	none
;;; returns:	none
;;; destroys:
VDP_INITTEXT::	ldx	#text_vdp_regs	;initialize registers
		bsr	VDP_SET_REGS
		bsr	VDP_CLEAR	;clear VRAM
; copy character set to pattern table
		ldd	#(VRAM|TEXT_PATTABLE)
		stb	VDP_REG
		sta	VDP_REG
		ldx	#TEXTFONT
		ldb	#128
		bsr	VDP_LOADPATS
		rts


;;; set VDP registers
;;; arguments:	pointer to 8-byte register set in X
;;; returns:	none
;;; destroys:	A,B,X
VDP_SET_REGS::	ldb	#0x80		;B holds register number, start at 0
1$:		lda	,x+		;A holds register value
		sta	VDP_REG		;write data byte
		stb	VDP_REG		;then write register number
		incb
		cmpb	#0x88
		bne	1$


;;; load patterns into VRAM at current VRAM address
;;; arguments:	VRAM address should be set already
;;;		pointer to start of first pattern in X
;;;		number of patterns (8 byte blocks) in B
;;;		(0 in B copies 256 patterns)
;;; returns:	X points to byte after last byte copied
;;; destroys:	A, B, X
VDP_LOADPATS::	lda	,x+		;copy unrolled 8 times
		sta	VDP_VRAM
		lda	,x+
		sta	VDP_VRAM
		lda	,x+
		sta	VDP_VRAM
		lda	,x+
		sta	VDP_VRAM
		lda	,x+
		sta	VDP_VRAM
		lda	,x+
		sta	VDP_VRAM
		lda	,x+
		sta	VDP_VRAM
		lda	,x+
		sta	VDP_VRAM
		decb
		bne	VDP_LOADPATS
		rts

;;; load patterns. inverted, into VRAM at current VRAM address
;;; arguments:	VRAM address should be set already
;;;		pointer to start of first pattern in X
;;;		number of patterns (8 byte blocks) in B
;;;		(0 in B copies 256 patterns)
;;; returns:	X points to byte after last byte copied
;;; destroys:	A, B, X
;;;
;;; patterns are bit-flipped before being loaded into VRAM
VDP_LOADIPATS::	lda	,x+		;copy unrolled 8 times
		coma
		sta	VDP_VRAM
		lda	,x+
		coma
		sta	VDP_VRAM
		lda	,x+
		coma
		sta	VDP_VRAM
		lda	,x+
		coma
		sta	VDP_VRAM
		lda	,x+
		coma
		sta	VDP_VRAM
		lda	,x+
		coma
		sta	VDP_VRAM
		lda	,x+
		coma
		sta	VDP_VRAM
		lda	,x+
		coma
		sta	VDP_VRAM
		decb
		bne	VDP_LOADIPATS
		rts

;;; print a positioned string into VRAM
;;; a "positioned string" is a null-terminated string,
;;; prefixed with a two-byte destination address (screen position)
;;; arguments:	pointer to positioned string in X
;;; returns:	X advanced
;;; destroys:	A, B
VDP_PRINTPSTR::	ldd	,x++		;read two bytes into D

;;; print a null-terminated string into VRAM
;;; arguments:	VRAM address in D
;;;		pointer to start of string in X
;;; returns:	X advanced
;;; destroys:	A, B
VDP_PRINTSTR::	ora	#0x40		;set address marker
		stb	VDP_REG		;set low byte of address
		sta	VDP_REG		;set high byte of address

;;; print a null-terminated string into VRAM at current address
;;; arguments:	pointer to start of string in X
;;; returns:	X advanced
;;; destroys:	B
VDP_PRINTSTRC::	ldb	,x+
		beq	vpdone		;stop when nul
		stb	VDP_VRAM
		bra	VDP_PRINTSTRC
vpdone:		rts


;;; set the VRAM address
;;; arguments:	address in D
;;; returns:	none
;;; destroys:	A
VDP_SETADDR::	ora	#0x40		;set address marker
vdpwrite:	stb	VDP_REG		;set low byte of address
		sta	VDP_REG		;set high byte of address
		rts


;;; simple method to print a character into VRAM 
;;; may be used for the OUTCH vector
;;; arguments:	character in B
;;; returns:	none
;;; destroys:	none
VDP_OUTCH::	stb	VDP_VRAM
		rts


;;; turn on the display after setup with VDP_INITTEXT
;;; arguments:	none
;;; returns:	none
;;; destroys:	A,B
VDP_TEXT_ON::	ldd	#0xD081
		sta	VDP_REG
		stb	VDP_REG
		rts


;;; text mode registers
TEXT_REG_1	.equ	0x90		;text mode, 16K, display off, ints off
text_vdp_regs:	.fcb	0x00		;text mode
		.fcb	TEXT_REG_1
		.fcb	TEXT_NAMETABLE/0x0400
		.fcb	0x00		;no colors
		.fcb	TEXT_PATTABLE/0x0800
		.fcb	0x00		;no sprite attributes
		.fcb	0x00		;no sprite patterns
		.fcb	0xF1		;white text, black background

;;; 6x8 console font
TEXTFONT::
	.include "textfont.inc"
TEXTFONT_END	.equ	.
