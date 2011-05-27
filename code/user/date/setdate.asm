; vim:noet:sw=8:ts=8:ai:syn=as6809
; Matt Sarnoff (msarnoff.org/6809) - September 15, 2010
;
; Set the date in a DS1307 real-time clock and print it

	.nlist
	.include "../../rom/6809.inc"
	.include "../../rom/rom06.inc"
	.list

	.area	_CODE(ABS)
	.org	USERPROG_ORG
		lds	#RAMEND+1	;set up stack pointer
		jsr	I2C_INIT
		jsr	TEXT_CONSOLE

; prompt for month
		ldx	#monthprompt
		jsr	OUTSTR
		ldx	#VALIDATE_NUM
		stx	RLVALIDATOR
		ldb	#3
		ldx	#BUF
		jsr	READLINE
		jsr	OUTNL
		jsr	READHEX
		stb	MONTH
; prompt for date
		ldx	#dateprompt
		jsr	OUTSTR
		ldb	#3
		ldx	#BUF
		jsr	READLINE
		jsr	OUTNL
		jsr	READHEX
		stb	DATE
; prompt for year
		ldx	#yearprompt
		jsr	OUTSTR
		ldb	#3
		ldx	#BUF
		jsr	READLINE
		jsr	OUTNL
		jsr	READHEX
		stb	YEAR
; prompt for weekday
		ldx	#weekdayprompt
		jsr	OUTSTR
		ldb	#2
		ldx	#BUF
		jsr	READLINE
		jsr	OUTNL
		jsr	READHEX
		stb	WEEKDAY
; prompt for hour
		ldx	#hourprompt
		jsr	OUTSTR
		ldb	#3
		ldx	#BUF
		jsr	READLINE
		jsr	OUTNL
		jsr	READHEX
		stb	HOURS
; prompt for minutes
		ldx	#minutesprompt
		jsr	OUTSTR
		ldb	#3
		ldx	#BUF
		jsr	READLINE
		jsr	OUTNL
		jsr	READHEX
		stb	MINUTES
; prompt for seconds
		ldx	#secondsprompt
		jsr	OUTSTR
		ldb	#3
		ldx	#BUF
		jsr	READLINE
		jsr	OUTNL
		jsr	READHEX
		andb	#0b01111111	;ensure clock halt bit is clear
		stb	SECONDS

; save to RTC
		ldx	#DATEBUF
		jsr	RTC_SET_TIME

; read back and print
		ldx	#DATEBUF2
		jsr	RTC_GET_TIME
		jsr	TIME_PRINT

		bra	.
		;swi2			;return

	.include "../include/i2c.asm"
	.include "../include/ds1307.asm"
	.include "../include/numio.asm"
	.include "../include/readline.asm"

DATEBUF		.equ	.
SECONDS:	.rmb	1
MINUTES:	.rmb	1
HOURS:		.rmb	1
WEEKDAY:	.rmb	1
DATE:		.rmb	1
MONTH:		.rmb	1
YEAR:		.rmb	1
BUF:		.rmb	4
DATEBUF2:	.rmb	7

monthprompt:	.asciz	"Month? (1-12) "
dateprompt:	.asciz	"Date? (1-31) "
yearprompt:	.asciz	"Year? (00-99) "
weekdayprompt:	.asciz	"Day of week? (1=Sun, 7=Sat) "
hourprompt:	.asciz	"Hour? (0-23) "
minutesprompt:	.asciz	"Minutes? (00-59) "
secondsprompt:	.asciz	"Seconds? (00-59) "
