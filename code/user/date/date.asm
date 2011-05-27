; vim:noet:sw=8:ts=8:ai:syn=as6809
; Matt Sarnoff (msarnoff.org/6809) - September 15, 2010
;
; Read the date from a DS1307 real-time clock and print it

	.nlist
	.include "../../rom/6809.inc"
	.include "../../rom/rom06.inc"
	.list

	.area	_CODE(ABS)
	.org	USERPROG_ORG
		lds	#RAMEND+1	;set up stack pointer
		jsr	I2C_INIT
		jsr	TEXT_CONSOLE

		ldb	#0b00010001
		jsr	RTC_SET_CR

		ldx	#datebuf
		jsr	RTC_GET_TIME
		jsr	TIME_PRINT
		bra	.

	.include "../include/i2c.asm"
	.include "../include/ds1307.asm"

datebuf:	.fcb	0,0,0,0,0,0,0
