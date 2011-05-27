; vim:noet:sw=8:ts=8:ai:syn=as6809
; Matt Sarnoff (msarnoff.org/6809) - January 25, 2011
;

;;; counts number of 16KB memory pages present
;;; arguments:	none
;;; returns:	number of pages in NUMRAMPAGES
;;;		total memory size, in BCD kilobytes, in RAM_KB_BCD
;;; destroys:	overwrites first byte of each 16K page
CALCRAMSIZE::
; clear starting byte of all 256 possible pages
		ldd	#0x0016		;assume at least one page
		std	*RAM_KB_BCD
1$:		sta	PAGE
		clr	XRAMSTART
		inca
		bne	1$
; set starting byte of page 0 to magic value (all others will be 0)
		clr	PAGE
		lda	#0xA5
		sta	0x0000
; iterate over all pages until we wrap around
; at that point, the value in 0x8000 should be the magic value
countpages:	inc	PAGE
		lda	#0xA5
		cmpa	XRAMSTART
		beq	countdone
		lda	#0x16		;add 16 to KB count
		adda	*RAM_KB_BCD+1
		daa
		sta	*RAM_KB_BCD+1
		lda	#0		;don't clear carry flag
		adca	*RAM_KB_BCD
		daa
		sta	*RAM_KB_BCD
		bra	countpages
; get page count
countdone:	clra
		ldb	PAGE
		decb		;make sure 0 is interpreted as 256
		addd	#1
		stb	*NUMRAMPAGES
		rts

