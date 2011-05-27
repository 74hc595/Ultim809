; vim:noet:sw=8:ts=8:ai:syn=as6809
; Matt Sarnoff (msarnoff.org/6809) - July 5, 2010
;
;************ Pseudorandom number generator ************
;Uses a 32-bit Galois linear feedback shift register.
;Not that great, but at least it doesn't require multiplication or division.


SETRANDOMSEED::	ldd	#0x1234
		std	RANDSEED
		ldd	#0x5678
		std	RANDSEED+2
		rts

;;; generate a pseudorandom bit
;;; arguments:	none
;;; returns:	bit in C flag
;;; destroys:	A,B
RANDBIT::	lsr	RANDSEED	;shift right one bit
		ror	RANDSEED+1
		ror	RANDSEED+2
		ror	RANDSEED+3
		pshs	cc		;save carry (output) bit
		bcc	randbitdone	;don't xor if lsb is 0
		ldd	RANDSEED	;xor with 0xD0000001
		eora	#0xD0		;(x^32 + x^31 + x^29 + x + 1)
		eorb	#0x00
		std	RANDSEED
		ldd	RANDSEED+2
		eora	#0x00
		eorb	#0x01
		std	RANDSEED+2
randbitdone:	puls	pc,cc
		
;;; generate a pseudorandom byte from 8 bits
;;; arguments:	none
;;; returns:	byte in B
;;; destroys:	A
RANDBYTE::	leas	-1,s
		bsr	RANDBIT
		ror	,s
		bsr	RANDBIT
		ror	,s
		bsr	RANDBIT
		ror	,s
		bsr	RANDBIT
		ror	,s
		bsr	RANDBIT
		ror	,s
		bsr	RANDBIT
		ror	,s
		bsr	RANDBIT
		ror	,s
		bsr	RANDBIT
		ror	,s
		puls	b,pc

;;; generate a pseudorandom byte between 0 and A-1
;;; arguments:	maximum in A
;;; returns:	byte in B
;;; destroys:	A,B
;;;
;;; Calculates the number of bits required and generates numbers until one is
;;; found within the specified range.
;;; Does not require division, and thus does not suffer from modulo bias.
RANDBYTERANGE::	cmpa	#1		;input of 0 or 1 always returns 0
		bls	randzero
		deca			;subtract 1
		pshs	a		;save range max
; find the number of random bits needed
; shift A left until a 1 is encountered
		ldb	#9		;number of bits needed
1$:		decb
		lsla
		bcc	1$
		pshs	b		;save number of bits
; generate random numbers until one within the range is found
		leas	-2,s		;bytes for bit count and rand. number
;---- random byte loop begin
genrandbyte:	lda	2,s
		sta	1,s		;copy bit count
		clr	,s		;clear random number accumulator
;------ random bit loop begin
2$:		bsr	RANDBIT		;get a bit
		rol	,s		;shift it into accumulator
		dec	1,s		;decrement bit count
		bne	2$		;get more if needed
;------ random bit loop end
		ldb	,s		;is the number in range?
		cmpb	3,s
		bhi	genrandbyte	;too high? try another
;---- random byte loop end
		leas	4,s		;clean up stack
		rts			;return number in B
randzero:	clrb
		rts


RANDSEED:	.rmb	4		;seed bytes (shift register)

	.if 0
RANDTEST:	ldx	#testtable
1$:		clr	,x+
		cmpx	#testtable+512
		bne	1$

		ldy	#0x20
2$:		tfr	y,d
		jsr	OUTDECUW
		jsr	OUTNL
		pshs	y
		ldu	#testtable
		ldy	#0xffff
3$:		jsr	RANDBYTE
		clra
		lslb			;multiply by 2 to get histogram offset
		rola
		ldx	d,u		;get histogram value
		leax	1,x		;increment histogram value
		stx	d,u		;store back in histogram
		leay	-1,y		;decrement count
		cmpy	#0
		bne	3$
		puls	y
		leay	-1,y
		cmpy	#0
		bne	2$

		ldx	#testtable
		clrb
		pshs	b
4$:		ldb	,s
		jsr	OUTDECUB
		ldb	#',
		jsr	[OUTCH]
		ldd	,x++
		jsr	OUTDECUW
		jsr	OUTNL
		inc	,s
		cmpx	#testtable+512
		bne	4$
		leas	1,s
		rts
testtable:	.rmb	512
	.endif
