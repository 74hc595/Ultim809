; vim:noet:sw=8:ts=8:ai:syn=as6809
; Matt Sarnoff (msarnoff.org/6809) - May 13, 2010
;

REQUEST_URL	.equ	0xF8
REQUEST_DATA	.equ	0xF9
HAVE_DATA	.equ	0xFA

RSP_HAS_DATA	.equ	0xFC
RSP_DATA	.equ	0xFD
RSP_HTTP_STATUS	.equ	0xFE
RSP_ERROR	.equ	0x00

;;; fetch the entire contents of a URL into memory
;;; arguments:	pointer to URL in X
;;;		data destination pointer in Y
;;; returns:	data copied
;;;		Z flag clear if an error occurred
;;; destroys:	A,B,X
HTTP_GET_URL::	ldb	#REQUEST_URL	;send command
		jsr	UART_OUTCH
		bsr	UART_SENDSTR	;send string
		clrb			;send null terminator
		jsr	UART_OUTCH
; wait for response
		jsr	UART_INCH	;get response byte
		cmpb	#RSP_ERROR
		beq	http_error
		jsr	UART_INCH	;get status code
		pshs	b
		jsr	UART_INCH
		puls	a
		cmpd	#200
		bne	http_error
; request data
datarequest:	ldx	#datacount	;send command
		lda	#3
		bsr	UART_SENDBYTES
; wait for data response
		jsr	UART_INCH	;get response byte
		cmpb	#0		;data?
		beq	http_done	;nope, done
; get data length
		jsr	UART_INCH	;get msb
		pshs	b
		jsr	UART_INCH	;get lsb
		puls	a
; get data
		tfr	d,x
1$:		jsr	UART_INCH
		stb	,y+
		;ldb	#'B
		;stb	,y+
		leax	-1,x
		bne	1$
; ask for more data
		bra	datarequest

http_error:	andcc	#0b11111011	;clear Z flag
		rts

http_done:	clra
		rts

UART_SENDSTR:	ldb	,x+
		beq	sendstr_done
		jsr	UART_OUTCH
		bra	UART_SENDSTR
sendstr_done:	rts

UART_SENDBYTES:	ldb	,x+
		jsr	UART_OUTCH
		deca
		bne	UART_SENDBYTES
		rts

datacount:	.fcb	REQUEST_DATA
		.fdb	512
