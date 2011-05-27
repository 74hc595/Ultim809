; vim:noet:sw=8:ts=8:ai:syn=as6809
; Matt Sarnoff (msarnoff.org/6809) - May 15, 2011
;
; Text-mode console routines using the TMS9918A and PS/2 keyboard

;;; enable the text console
;;; arguments:	none
;;; returns:	none
TEXT_CONSOLE::	jsr	VDP_INITTEXT	;clear memory and setup charset
		ldd	#VRAM|TEXT_PATTABLE+(128*8)
		stb	VDP_REG
		sta	VDP_REG
		ldx	#TEXTFONT
		ldb	#128
		jsr	VDP_LOADIPATS	;load inverted character set
		ldd	#0
		std	*CURSORPOS
		ldd	#TEXT_OUTCH	;set up I/O routines
		std	*OUTCH
		ldd	#KBD_INCH
		std	*INCH
		jsr	VDP_TEXT_ON	;turn the on display
		ldd	#VRAM|0x0000	;initialize VRAM address
		stb	VDP_REG
		sta	VDP_REG
		jsr	cursor_invert
		jsr	KBD_INIT
		andcc	#0b11101111	;enable keyboard interrupt
		jsr	KBD_ENABLE
		rts

;;; clear the screen and return the cursor to the home position
;;; arguments:	none
;;; returns:	none
;;; destroys:	none
TEXT_CLEAR::	pshs	a,b,x
text_clear:	ldd	#0
		std	*CURSORPOS
		ora	#0x40
		stb	VDP_REG
		sta	VDP_REG
		ldx	#960
		clra
		jsr	VDP_FILL
		bsr	cursor_invert
		puls	a,b,x,pc

;;; print a character on the screen, interpreting the following characters:
;;; - carriage return
;;; - newline 
;;; - backspace
;;; - clear (Ctrl-L)
;;; arguments:	character in B
;;; returns:	none
;;; destroys:	none
TEXT_OUTCH::	pshs	a,b,u
		cmpb	#0x0A		;newline
		beq	text_nop
		cmpb	#0x0D
		beq	text_crlf
		cmpb	#0x08
		beq	text_backspace
		cmpb	#0x7F
		beq	text_backspace
		cmpb	#0x0C
		beq	text_clear
		bsr	cursor_invert
		stb	VDP_VRAM	;print character
		ldd	*CURSORPOS	;advance cursor position
		addd	#1
		bra	text_setpos
text_nop:	puls	a,b,u,pc

text_lf:	bsr	cursor_invert
		ldd	*CURSORPOS	;add 40 to cursor position
_text_lf:	addd	#40
text_setpos:	cmpd	#0x0000+960 ;need to scroll?
		blo	_text_setpos
		bsr	text_scrollup
_text_setpos:	std	*CURSORPOS	;store new position
		ora	#0x40		;update VRAM address
		stb	VDP_REG
		sta	VDP_REG
		bsr	cursor_invert
		puls	a,b,u,pc

text_cr:	bsr	_text_cr
		bra	text_setpos

_text_cr:	bsr	cursor_invert
		ldd	*CURSORPOS	;divide cursor position by 8
		lsra
		rorb
		lsra
		rorb
		lsra
		rorb
		ldu	#linenumbers	;get the current line number
		ldb	b,u
		lda	#40		;compute new line address
		mul
		rts

text_crlf:	bsr	_text_cr
		bra	_text_lf

text_backspace:	bsr	cursor_invert
		ldd	*CURSORPOS	;subtract 1 from cursor position
		beq	text_nop
		subd	#1
		bra	text_setpos

cursor_invert:	pshs	b
		ldd	*CURSORPOS	;read character at cursor position
		stb	VDP_REG
		sta	VDP_REG
		ldb	VDP_VRAM
		eorb	#0b10000000	;invert msb
		pshs	b
		ldd	*CURSORPOS
		ora	#0x40
		stb	VDP_REG
		sta	VDP_REG
		puls	b
		stb	VDP_VRAM	;store new character
		ldd	*CURSORPOS	;restore VRAM address
		ora	#0x40		;(since it was autoincremented)
		stb	VDP_REG
		sta	VDP_REG
		puls	b,pc

text_scrollup:	lda	#23		;23 lines to scroll
		pshs	a
		ldd	#0x0000+40 ;temporary VRAM address
		pshs	d
		leas	-40,s		;grab us some stack space
;---- line scroll loop
text_grabline:	tfr	s,u		;pointer to start of temp buffer
		ldd	40,s		;set VRAM address
		stb	VDP_REG
		sta	VDP_REG
		lda	#40		;read a line from VRAM
1$:		ldb	VDP_VRAM	;get a byte
		stb	,u+		;store it in the temp buffer
		deca
		bne	1$

text_moveline:	ldd	40,s		;get VRAM address
		subd	#40		;move up one line
		ora	#0x40		;set VRAM address for write
		stb	VDP_REG
		sta	VDP_REG
		tfr	s,u
		lda	#40
2$:		ldb	,u+		;write the buffer back to VRAM
		stb	VDP_VRAM
		deca
		bne	2$
;---- end line scroll loop
		ldd	40,s		;advance to next line
		addd	#40
		std	40,s
		dec	42,s		;decrement line count
		bne	text_grabline
; blank the last line
		bsr	clear_line
; put the cursor at the start of the bottom line
		ldd	#0x0000+(40*23)
		leas	43,s		;reclaim stack space
		rts

;;; move the cursor to the first position on the specified line (in A)
;;; and clear the line
;;; arguments:	line number in A, indexed from 1 (for ANSI compatibility)
;;; returns:	none
;;; destroys:	A,B
TEXT_CLRLINE::	bsr	TEXT_SETLINE
		;fall through to TEXT_CLRCURLN

;;; clear current line and return cursor to start
;;; arguments:	none
;;; returns:	none
;;; destroys:	A,B
TEXT_CLRCURLN::	jsr	_text_cr
		pshs	d		;save VRAM address
		std	*CURSORPOS
		ora	#0x40
		stb	VDP_REG
		sta	VDP_REG
		bsr	clear_line
		puls	d		;restore VRAM address
__text_setpos:	std	*CURSORPOS	;store new position
		ora	#0x40		;update VRAM address
		stb	VDP_REG
		sta	VDP_REG
		jmp	cursor_invert

clear_line:	lda	#40
		ldb	#0x20
1$:		stb	VDP_VRAM
		deca
		bne	1$
		rts

;;; move the cursor to the first position on the specified line
;;; arguments:	line number in A, indexed from 1 (for ANSI compatibility)
;;; returns:	none
;;; destroys:	A,B
TEXT_SETLINE::	deca			;make zero-indexed
		pshs	a
		jsr	cursor_invert
		puls	a		;compute line position
		ldb	#40
		mul
		bra	__text_setpos	;update cursor position
	
;;; move the cursor to the specified column on the current line
;;; arguments:	column number in B, indexed from 1
;;; returns:	none
;;; destroys:	A,B
TEXT_SETCOL::	decb			;make zero-indexed
		pshs	b
		jsr	_text_cr	;return to start of line
		addb	,s		;add offset to cursor position
		adca	#0
		leas	1,s
		bra	__text_setpos

;;; keyboard input routine, blocks until a keystroke is received
;;; arguments:	none
;;; returns:	ASCII character in B
;;; destroys:	none
KBD_INCH::	pshs	a	
getkey:		jsr	KBD_GETCODE	;get a scancode
		beq	getkey		;loop if there aren't any
		lda	*KEYSTATE	;ok, convert scancode to ASCII
		jsr	KBD_DECODE
		sta	*KEYSTATE
		tstb
		beq	getkey		;try again if 0 is returned
		puls	a,pc		;otherwise, return character

linenumbers:	.fcb	0, 0, 0, 0, 0
		.fcb	1, 1, 1, 1, 1
		.fcb	2, 2, 2, 2, 2
		.fcb	3, 3, 3, 3, 3
		.fcb	4, 4, 4, 4, 4
		.fcb	5, 5, 5, 5, 5
		.fcb	6, 6, 6, 6, 6
		.fcb	7, 7, 7, 7, 7
		.fcb	8, 8, 8, 8, 8
		.fcb	9, 9, 9, 9, 9
		.fcb	10,10,10,10,10
		.fcb	11,11,11,11,11
		.fcb	12,12,12,12,12
		.fcb	13,13,13,13,13
		.fcb	14,14,14,14,14
		.fcb	15,15,15,15,15
		.fcb	16,16,16,16,16
		.fcb	17,17,17,17,17
		.fcb	18,18,18,18,18
		.fcb	19,19,19,19,19
		.fcb	20,20,20,20,20
		.fcb	21,21,21,21,21
		.fcb	22,22,22,22,22
		.fcb	23,23,23,23,23
