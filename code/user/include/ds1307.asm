; vim:noet:sw=8:ts=8:ai:syn=as6809
; Matt Sarnoff (msarnoff.org/6809) - September 16, 2010
;
;************ DS1307 real-time clock routines ************

RTC_ID_WRITE	.equ	0xD0
RTC_ID_READ	.equ	0xD1

; time/date field offsets
RTC_SEC		.equ	0	;00-59
RTC_MIN		.equ	1	;00-59
RTC_HOUR	.equ	2	;01-12 or 00-23
RTC_WEEKDAY	.equ	3	;1-7
RTC_DATE	.equ	4	;01-31
RTC_MONTH	.equ	5	;01-12
RTC_YEAR	.equ	6	;00-99
RTC_CONTROL	.equ	7
RTC_NVRAM	.equ	8
RTC_12HR_BIT	.equ	0b01000000

;;; read time into buffer pointed to by X
;;; arguments:	pointer to buffer in X (7 bytes)
;;; returns:	time written to buffer
;;; destroys:	A,B
RTC_GET_TIME::	pshs	x
; send start condition
		jsr	I2C_START
; send start address
		ldb	#RTC_ID_WRITE
		jsr	I2C_WRITE
		ldb	#RTC_SEC
		jsr	I2C_WRITE
		jsr	I2C_STOP
; read bytes
		jsr	I2C_START
		ldb	#RTC_ID_READ
		jsr	I2C_WRITE
; get seconds
		jsr	I2C_READ_ACK
		stb	,x+
; get minutes
		jsr	I2C_READ_ACK
		stb	,x+
; get hours
		jsr	I2C_READ_ACK
		stb	,x+
; get day of week
		jsr	I2C_READ_ACK
		stb	,x+
; get date
		jsr	I2C_READ_ACK
		stb	,x+
; get month
		jsr	I2C_READ_ACK
		stb	,x+
; get year
		jsr	I2C_READ_NACK
		stb	,x
		jsr	I2C_STOP
		puls	x,pc


;;; store time from buffer pointed to by X
;;; arguments:	pointer to buffer in X (7 bytes)
;;; returns:	none
;;; destroys:	A,B,X
RTC_SET_TIME::	
; send start condition
		jsr	I2C_START
; send start address
		ldb	#RTC_ID_WRITE
		jsr	I2C_WRITE
		ldb	#RTC_SEC
		jsr	I2C_WRITE
; send seconds
		ldb	,x+
		jsr	I2C_WRITE
; send minutes
		ldb	,x+
		jsr	I2C_WRITE
; send hours
		ldb	,x+
		jsr	I2C_WRITE
; send weekday
		ldb	,x+
		jsr	I2C_WRITE
; send date
		ldb	,x+
		jsr	I2C_WRITE
; send month
		ldb	,x+
		jsr	I2C_WRITE
; send year
		ldb	,x+
		jsr	I2C_WRITE
; send stop condition
		jsr	I2C_STOP
		rts


;;; read a byte from the DS1307
;;; arguments:	address in A
;;; returns:	byte value in B
RTC_GET_BYTE::	pshs	a
; send start condition
		jsr	I2C_START
; send address
		ldb	#RTC_ID_WRITE
		jsr	I2C_WRITE
		puls	b		;pull address argument from stack
		jsr	I2C_WRITE
		jsr	I2C_STOP
; read byte
		jsr	I2C_START
		ldb	#RTC_ID_READ
		jsr	I2C_WRITE
; get byte
		jsr	I2C_READ_NACK	;byte is now in B
; send stop condition
		jsr	I2C_STOP
		rts


;;; set a byte in the DS1307
;;; arguments:	address in A, new value in B
;;; returns:	none
;;; destroys:	A,B
RTC_SET_BYTE::	pshs	a,b
; send start condition
		jsr	I2C_START
; send address
		ldb	#RTC_ID_WRITE
		jsr	I2C_WRITE
		puls	b		;pull address argument from stack
		jsr	I2C_WRITE
; send byte
		puls	b		;pull value argument from stack
		jsr	I2C_WRITE
; send stop condition
		jsr	I2C_STOP
		rts


;;; read the DS1307 control register
;;; arguments:	none
;;; returns:	register value in B
;;; destroys:	A
RTC_GET_CR::	lda	#RTC_CONTROL
		bra	RTC_GET_BYTE


;;; set DS1307 control register
;;; arguments:	new control register value in B
;;; returns:	none
;;; destroys:	A,B
RTC_SET_CR::	lda	#RTC_CONTROL
		bra	RTC_SET_BYTE


;;; start running the oscillator
;;; arguments:	none
;;; returns:	none
;;; destroys:	A,B
RTC_RUN::	lda	#RTC_SEC		;get seconds byte
		bsr	RTC_GET_BYTE
		andb	#0b01111111		;clear clock halt bit
		lda	#RTC_SEC
		bra	RTC_SET_BYTE		;set new byte value


;;; stop the oscillator
;;; arguments:	none
;;; returns:	none
;;; destroys:	A,B
RTC_HALT::	lda	#RTC_SEC		;get seconds byte
		bsr	RTC_GET_BYTE
		orb	#0b10000000		;set clock halt bit
		lda	#RTC_SEC
		bra	RTC_SET_BYTE


;;; check if the RTC's oscillator is running
;;; arguments:	none
;;; returns:	Z flag set if oscillator running
RTC_RUNNING::	lda	#RTC_SEC		;get seconds byte
		bsr	RTC_GET_BYTE
		tstb				;check if bit 7 is set
		bne	ch_set
		andcc	#0b11111011		;clear Z flag
		rts
ch_set:		orcc	#0b00000100		;set Z flag
		rts


;;; print time in 7-byte buffer pointed to by X
;;; arguments:	pointer to time buffer in X
;;; returns:	none
;;; destroys:	A,B
TIME_PRINT::	tfr	x,y
; print weekday
		ldb	RTC_WEEKDAY,y
		lslb
		lslb
		ldx	#daystrs
		abx
		lda	#4
		jsr	OUTSTRN
; print month
		ldb	RTC_MONTH,y
		bitb	#0b00010000	;check for month >= 10
		beq	monthmul4
		andb	#0b00001111	;mask off 10 bit
		addb	#10		;add 10
monthmul4:	lslb			;multiply by 4 to get string offset
		lslb
		ldx	#monthstrs
		abx
		lda	#4
		jsr	OUTSTRN
; print date
		ldb	RTC_DATE,y
		jsr	OUTHEXB
		jsr	OUTSP
; print year
		ldb	#'2
		jsr	[OUTCH]
		ldb	#'0
		jsr	[OUTCH]
		ldb	RTC_YEAR,y
		jsr	OUTHEXB
		jsr	OUTSP
; print 12 or 24 hour time
		ldb	RTC_HOUR,y
		bitb	#RTC_12HR_BIT
		bne	print12hr
print24hr:	andb	#0b00111111
printhr:	jsr	OUTHEXB
		ldb	#':
		jsr	[OUTCH]
; print minutes
		ldb	RTC_MIN,y
		jsr	OUTHEXB
		ldb	#':
		jsr	[OUTCH]
; print seconds
		ldb	RTC_SEC,y
		andb	#0b01111111
		jsr	OUTHEXB
; print AM/PM if necessary
		ldb	RTC_HOUR,y
		bitb	#RTC_12HR_BIT
		bne	printampm
		jsr	OUTNL
		rts

print12hr:	andb	#0b00011111
		bra	printhr

printampm:	tfr	b,a
		jsr	OUTSP
		ldb	#'A
		bita	#0b00100000
		beq	doprintampm
		ldb	#'P
doprintampm:	jsr	[OUTCH]
		ldb	#'M
		jsr	[OUTCH]
		jsr	OUTNL
		rts

monthstrs:	.ascii	"??? "
		.ascii	"Jan "
		.ascii	"Feb "
		.ascii	"Mar "
		.ascii	"Apr "
		.ascii	"May "
		.ascii	"Jun "
		.ascii	"Jul "
		.ascii	"Aug "
		.ascii	"Sep "
		.ascii	"Oct "
		.ascii	"Nov "
		.ascii	"Dec "

daystrs:	.ascii	"??? "
		.ascii	"Sun "
		.ascii	"Mon "
		.ascii	"Tue "
		.ascii	"Wed "
		.ascii	"Thu "
		.ascii	"Fri "
		.ascii	"Sat "
