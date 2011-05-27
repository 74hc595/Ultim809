; vim:noet:sw=8:ts=8:ai:syn=as6809
; Matt Sarnoff (msarnoff.org/6809) - May 26, 2010

;************ Numeric input/output routines ************

;;; read hex digits from the string in X into a 16-bit integer
;;; stops after the first invalid character
;;; arguments:	string pointer in X
;;; returns:	value in D
;;; destroys:	X advanced
READHEX::	ldd	#0
		pshs	d		;temporary result is on stack
readhexdigit:	ldb	,x+		;get a character
		cmpb	#'0		;is it a decimal digit?
		blo	nothex
		cmpb	#'9
		bhi	testaf
		subb	#'0		;it's a decimal digit
		bra	addhexdigit	;we're good
testaf:		cmpb	#'A		;is it between A and F?
		blo	nothex
		cmpb	#'F
		bhi	testaflower
		subb	#55
		bra	addhexdigit
testaflower:	cmpb	#'a
		blo	nothex
		cmpb	#'f
		bhi	nothex
		subb	#87
addhexdigit:	lsl	1,s		;multiply temporary by 16
		rol	,s
		lsl	1,s
		rol	,s
		lsl	1,s
		rol	,s
		lsl	1,s
		rol	,s
		orb	1,s		;or digit into lower nibble
		stb	1,s
		bra	readhexdigit
nothex:		leax	-1,x		;back up x
		puls	d		;pop result into D
		clv
		rts

;;; read signed decimal digits from the string in X into a 16-bit integer
;;; stops after the first invalid character
;;; arguments:	string pointer in X
;;; returns:	value in D
;;; destroys:	X advanced
READDEC::	ldd	#0
		pshs	b		;sign flag
		pshs	d		;temporary result on stack
		ldb	,x		;check for minus sign
		cmpb	#'-
		bne	readdecdigit
		inc	2,s		;set sign flag
		leax	1,x		;advance to next character
readdecdigit:	ldb	,x+		;get a character
		cmpb	#'0		;is it a decimal digit?
		blo	notdec
		cmpb	#'9
		bhi	notdec
		subb	#'0		;it's a decimal digit
		pshs	b		;save digit
		lsl	2,s		;multiply temporary by 10
		rol	1,s		;temporary now multiplied by 2
		ldd	1,s
		lslb
		rola
		lslb
		rola			;temporary now multiplied by 8
		addd	1,s		;add times-2 to times-8 to get times-10
		addb	,s		;add digit
		adca	#0		;propagate carry
		std	1,s		;save result back on stack
		puls	b		;don't need temp digit anymore
		bra	readdecdigit
notdec:		leax	-1,x		;back up x
		puls	d		;pop result into D
		tst	,s		;negate result?
		beq	decdone
		coma			;take twos complement of result
		comb
		addd	#1
decdone:	leas	1,s		;discard sign flag
		clv
		rts

;;; print byte as signed decimal
;;; arguments:	byte in B
;;; returns:	none
;;; destroys:	A,B
OUTDECSB::	tfr	b,a		;move b to a so we can call outdecub
		tsta			;is the number positive?
		bpl	outdecub_a	;yes, just print it unsigned
		ldb	#'-		;no, print a negative sign
		jsr	[OUTCH]
		nega			;make a positive (absolute value)
		bra	outdecub_a	;print unsigned

;;; print byte as unsigned decimal
;;; arguments:	byte in B
;;; returns:	none
;;; destroys:	A,B
OUTDECUB::	tfr	b,a		;use a instead of b
outdecub_a:	cmpa	#100		;determine number of digits
		bhs	odu100a		;3 digits to print
		cmpa	#10
		bhs	odu10a		;2 digits to print
		tfr	a,b		;1 digit to print:
		addb	#'0		;  just execute it inline
		jmp	[OUTCH]		;  instead of branching

;;; print byte as unsigned decimal with leading zeros
;;; arguments:	byte in B
;;; returns:	none
;;; destroys:	A,B
OUTDECZB::	tfr	b,a
odu100a:	ldb	#'/		;one less than ascii zero
1$:		incb
		suba	#100		;repeatedly subtract 100
		bcc	1$		;underflow? digit is zero
		jsr	[OUTCH]		;print digit in b
		adda	#100		;add 100 back
odu10a:		ldb	#'/		;one less than ascii zero
2$:		incb
		suba	#10		;repeatedly subtract 10
		bcc	2$		;underflow? digit is zero
		jsr	[OUTCH]		;print digit in b
		adda	#10+'0		;get ascii value of last digit
		tfr	a,b		;bring last digit back to b
		jmp	[OUTCH]		;print digit in b

;;; print word as signed decimal
;;; arguments:	word in D
;;; returns:	none
;;; destroys:	D
OUTDECSW::	tsta			;is the number positive?
		bpl	OUTDECUW	;yes, just print it unsigned
		pshs	b
		ldb	#'-		;no, print a negative sign
		jsr	[OUTCH]
		puls	b		;restore b
		coma			;make d positive (absolute value)
		comb			;  by flipping all the bits
		addd	#1		;  and adding 1
		bra	OUTDECUW


;;; print word as unsigned decimal
;;; arguments:	word in D
;;; returns:	none
;;; destroys:	D
;;; Uses repeated subtraction of 10000s, 1000s, 100s, etc. instead of
;;; the constant-time method (shift out bits and use BCD addition).
;;; Not only is this *faster*, but the output is five ASCII bytes
;;; (no need to unpack the result), only 2 bytes of stack are needed,
;;; and it's reentrant.
;;; Max runtime, for an input of 59999, is 597 cycles (not including
;;; cycles spent in the OUTCH subroutine.)
OUTDECUW::	pshs	b,cc		;need 2 bytes of temp storage:
					; 1,s used to save low byte of D
					;  ,s used for ascii character
		cmpd	#10000		;5 digits to print
		bhs	oduw10000a
		cmpd	#1000		;4 digits to print
		bhs	oduw1000a
		cmpd	#100		;3 digits to print
		bhs	oduw100a
		cmpb	#10		;2 digits to print
		bhs	oduw10a
		leas	2,s		;clean up temp storage; won't need it
		addb	#'0		;1 digit to print;
		jmp	[OUTCH]		;  just execute it inline

;;; print word as unsigned decimal with leading zeros
;;; arguments:	word in D
;;; returns:	none
;;; destroys:	D
OUTDECZW::	pshs	b,cc		;2 bytes of temp storage
oduw10000a:	ldb	#'/		;one less than ascii zero
		stb	,s
		ldb	1,s		;bring low byte back to b
1$:		inc	,s
		subd	#10000		;repeatedly subtract 10000
		bcc	1$
		addd	#10000		;add 10000 back
		stb	1,s		;save low byte to free up b
		ldb	,s		;bring ascii digit into b
		jsr	[OUTCH]		;print digit in b
oduw1000a:	ldb	#'/		;one less than ascii zero
		stb	,s
		ldb	1,s		;bring low byte back to b
2$:		inc	,s
		subd	#1000		;repeatedly subtract 1000
		bcc	2$
		addd	#1000		;add 1000 back
		stb	1,s		;save low byte to free up b
		ldb	,s		;bring ascii digit into b
		jsr	[OUTCH]		;print digit in b
oduw100a:	ldb	#'/		;one less than ascii zero
		stb	,s
		ldb	1,s		;bring low byte back to b
3$:		inc	,s
		subd	#100		;repeatedly subtract 100
		bcc	3$
		addd	#100		;add 100 back
		stb	1,s		;save low byte to free up b
		ldb	,s		;bring ascii digit into b
		jsr	[OUTCH]		;print digit in b
oduw10a:	lda	1,s		;tens digit only needs 8-bit arithmetic
		ldb	#'/		;  so we don't need the stack
4$:		incb
		suba	#10		;repeatedly subtract 10
		bcc	4$
		jsr	[OUTCH]		;print digit in b
		adda	#10+'0		;get ascii value of last digit
		tfr	a,b		;bring last digit back to b
		leas	2,s		;clean up temp storage before leaving
		jmp	[OUTCH]		;print digit in b

