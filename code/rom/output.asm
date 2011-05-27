; vim:noet:sw=8:ts=8:ai:syn=as6809
; Matt Sarnoff (msarnoff.org/6809) - May 26, 2010

;************ Console output routines ************
; Address OUTCH should contain a pointer to the 'character output' function;
; it should accept the character to print in B
; call with: jsr [OUTCH]

;;; print newline (CRLF)
;;; arguments:	none
;;; returns:	none
;;; destroys:	B
OUTNL::		ldb	#0x0d
		jsr	[OUTCH]
		ldb	#0x0a
		jmp	[OUTCH]

;;; print space
;;; arguments:	none
;;; returns:	none
;;; destroys:	B
OUTSP::		ldb	#0x20
		jmp	[OUTCH]

;;; print backspace
;;; arguments:	none
;;; returns:	none
;;; destroys:	B
OUTBS::		ldb	#0x08
		jmp	[OUTCH]

;;; print null-terminated string
;;; arguments:	string pointer in X
;;; returns:	none
;;; destroys:	B
OUTSTR::	ldb	,x+
		beq	osdone
		jsr	[OUTCH]
		bra	OUTSTR
osdone:		rts

;;; print null-terminated string followed by newline
;;; arguments:	string pointer in X
;;; returns:	none
;;; destroys:	B
OUTSTRNL::	ldb	,x+
		beq	OUTNL
		jsr	[OUTCH]
		bra	OUTSTRNL

;;; print n characters of a string, ignoring null terminator
;;; arguments:	string pointer in X
;;;		count in A (0-255)
;;; returns:	none
;;; destroys:	B
OUTSTRN::	tsta
		beq	osdone
		ldb	,x+
		jsr	[OUTCH]
		deca
		bra	OUTSTRN

;;; print word in D as hexadecimal
;;; arguments:	word in D (big-endian)
;;; returns:	none
;;; destroys:	D
OUTHEXW::	pshs	b		;save lsb
		tfr	a,b
		bsr	OUTHEXB		;print msb
outhexw2:	puls	b		;restore msb
		;fall through and print lsb

;;; print byte in B as hexadecimal
;;; arguments:	byte in B
;;; returns:	none
;;; destroys:	B
OUTHEXB::	pshs	b		;save for lsd
		lsrb
		lsrb
		lsrb
		lsrb
		bsr	OUTHEXD		;print msd
		puls	b		;restore lsd
		;fall through and print lsd

;;; print hexadecimal digit in lower 4 bits of B
;;; arguments:	digit in B
;;; returns:	none
;;; destroys:	B
OUTHEXD::	andb	#0b00001111	;lsd only
		orb	#'0
		cmpb	#'9+1		;decimal digit?
		blo	oxdprint	;if so, print it
		addb	#7		;no, add offset
oxdprint:	jmp	[OUTCH]


;;; print 4-digit BCD number in D without leading zeros
;;; arguments:	BCD number in D
;;; returns:	none
;;; destroys:	D
;;; Also can be used to print a hexadecimal number without leading zeros.
OUTBCDW::	tsta			;only 1 byte?
		beq	OUTBCDB
		bita	#0b11110000	;most significant digit?
		bne	OUTHEXW		;yes, print 4 digits
		exg	b,a		;3 digits, save lower two in A
		bsr	OUTHEXD		;print high digit
		tfr	a,b		;restore lower digits
		bra	OUTHEXB		;print lower digits

;;; print 2-digit BCD number in B without a leading zero
;;; arguments:	BCD number in B
;;; returns:	none
;;; destroys:	B
;;; Also can be used to print a hexadecimal number without a leading zero.
OUTBCDB::	bitb	#0b11110000	;most significant digit?
		bne	OUTHEXB		;yes, print 2 digits
		bra	OUTHEXD		;no, print 1 digit
