; vim:noet:sw=8:ts=8:ai:syn=as6809
; Matt Sarnoff (msarnoff.org/6809) - July 5, 2010

;************ Line input routine ************

;;; read a line from the console, with backspace support
;;; arguments:	pointer to string buffer in X
;;;		maximum character count in B
;;;		pointer to validation subroutine in RLVALIDATOR
;;; returns:	string copied to buffer
;;; destroys:	A,B
strbufstart	.equ	2
strbufend	.equ	0
READLINE::	pshs	x		;save buffer origin
		decb			;leave room for null char.
		abx			;save buffer end
		pshs	x
		ldx	strbufstart,s	;restore buffer origin
rl_getchar:	jsr	[INCH]
		cmpb	#NLCHAR		;return could be CR or LF
		beq	rl_linedone
		cmpb	#CRCHAR
		beq	rl_linedone
		cmpb	#BACKSPACECHAR	;handle delete or backspace
		beq	rl_deletechar
		cmpb	#DELETECHAR
		beq	rl_deletechar
		jsr	[RLVALIDATOR]	;validate character
		bvs	rl_getchar
rl_storechar:	cmpx	strbufend,s	;max amount of characters typed?
		bge	rl_getchar	;yes, don't store character
		jsr	[OUTCH]		;echo character
		stb	,x+		;store char in buffer
		bra	rl_getchar
rl_deletechar:	cmpx	strbufstart,s	;don't delete if at first char
		beq	rl_getchar
		jsr	OUTBS		;send delete sequence (\b space \b)
		jsr	OUTSP
		jsr	OUTBS
		ldb	#0		;overwrite last char with 0
		stb	,-x
		bra	rl_getchar
rl_linedone:	ldb	#0		;null-terminate the string
		stb	,x+
		leas	2,s		;throw away end address
		puls	x		;restore X
		rts

;;; validation function that accepts all characters
VALIDATE_ALL::	clv
		rts

;;; validation function that accepts only decimal digits
VALIDATE_NUM::	cmpb	#'0
		blo	vnum_fail
		cmpb	#'9
		bhi	vnum_fail
		clv
		rts
vnum_fail:	sev
		rts

;;; stores a pointer to the READLINE validation subroutine
;;; subroutine should:
;;;	- accept character in B
;;;	- should not modify B
;;;	- should set V flag if character is unacceptable
RLVALIDATOR:	.fdb	VALIDATE_ALL
