; vim:noet:sw=8:ts=8:ai:syn=as6809
; Matt Sarnoff (msarnoff.org/6809) - May 13, 2010
;

	.nlist
	.include "../../rom/6809.inc"
	.include "../../rom/rom06.inc"
	.list

PATTABLE	.equ	0x0000		;top third of pattern table
PATTABLE2	.equ	PATTABLE+0x0800	;middle third of pattern table
PATTABLE3	.equ	PATTABLE+0x1000	;bottom third of pattern table
NAMETABLE	.equ	0x1800		;name table
COLORTABLE	.equ	0x2000		;color table
SPRPATTABLE	.equ	0x3800		;sprite pattern table
SPRATTABLE	.equ	0x3C00		;sprite attribute table


VARSTART	.equ	0x80

NUM_ZIPCODES	.equ	4
ZIPCODE_LEN	.equ	5

; weather structure offsets
city		.equ	0
CITY_LEN	.equ	32
icon		.equ	city+CITY_LEN
temp		.equ	icon+1
TEMP_LEN	.equ	4
condition	.equ	temp+TEMP_LEN
CONDITION_LEN	.equ	18
highlow		.equ	condition+CONDITION_LEN
HIGHLOW_LEN	.equ	18
humidity	.equ	highlow+HIGHLOW_LEN
HUMIDITY_LEN	.equ	18
wind		.equ	humidity+HUMIDITY_LEN
WIND_LEN	.equ	18
WEATHER_SIZE	.equ	110


;------------------------------------------------------------------------------
; setup
;------------------------------------------------------------------------------
	.area	_CODE(ABS)
	.org	USERPROG_ORG
		lds	#RAMEND+1	;set up stack pointer
		ldd	#VBLANK		;set up interrupt vector
		std	IRQVEC
		jsr	VDP_CLEAR	;clear VRAM
		ldx	#vdp_regs	;set Graphics Mode II
		jsr	VDP_SET_REGS

; copy the patterns to all three sections of the pattern table
		ldd	#VRAM|PATTABLE
		stb	VDP_REG
		sta	VDP_REG
		lda	#3
		pshs	a
1$:		ldx	#GRAPHICS
		clrb			;0 = 256
		jsr	VDP_LOADPATS
		dec	,s
		bne	1$
		puls	a

; initialize the color table
		ldd	#VRAM|COLORTABLE
		stb	VDP_REG
		sta	VDP_REG
		lda	#3		;three copies of the color table
		pshs	a
2$:		ldx	#96*8
		lda	#0xF0		;black and white for the text
		jsr	VDP_FILL
		ldx	#COLORS		;then the rest of the colors
		ldb	#160
		jsr	VDP_LOADPATS
		dec	,s
		bne	2$
		puls	a

; enable the keyboard
		jsr	KBD_INIT
		andcc	#0b1110111
		jsr	KBD_ENABLE

; fetch the data
		jsr	KBD_INCH
		jsr	UPDATE

; show the data
		jsr	DRAW
		
; enable interrupts
		andcc	#0b11101111

; turn on the display
		ldd	#0xE081
		sta	VDP_REG
		stb	VDP_REG


;------------------------------------------------------------------------------
; logic loop
;------------------------------------------------------------------------------
loop:		jsr	KBD_GETCODE
		cmpb	#0x5a
		beq	refresh
		sync
		bra	.

refresh:	jsr	UPDATE
		bra	loop

;------------------------------------------------------------------------------
; vertical blanking interrupt handler
;------------------------------------------------------------------------------
VBLANK:		lda	VDP_REG		;read status, clear interrupt flag
		rti


;------------------------------------------------------------------------------
; subroutines
;------------------------------------------------------------------------------

;;; draw all weather blocks
;;; arguments:	none
;;; returns:	none
;;; destroys:	A,B,X,Y
DRAW:		ldx	#WEATHERDATA
		ldd	#NAMETABLE
		bsr	SHOW_WEATHER
		ldd	#NAMETABLE+(32*6)
		bsr	SHOW_WEATHER
		ldd	#NAMETABLE+(32*12)
		bsr	SHOW_WEATHER
		ldd	#NAMETABLE+(32*18)
		;fall through to show last blogk

;;; display a weather data block
;;; arguments:	pointer to struct in X
;;;		screen position in D
;;; returns:	X advanced
;;; destroys:	A,B
SHOW_WEATHER:	;stx	0xcd00
		pshs	x
		ora	#0x40		;enable VRAM
		tst	,x		;empty entry?
		lbeq	W_BLANKENTRY	;if so, blank it
		pshs	d		;save address
; print city
		addd	#1
		stb	VDP_REG
		sta	VDP_REG

		lda	#CITY_LEN-1
		leax	1,x
		bsr	W_PRINTSTRN
; show icon
		ldd	,s
		addd	#33
		jsr	W_PRINTICON

; print temperature
		ldd	,s
		addd	#69
		bsr	W_PRINTTEMP

; print condition
		ldd	,s
		addd	#45
		stb	VDP_REG
		sta	VDP_REG
		std	,s
		lda	#CONDITION_LEN
		bsr	W_PRINTSTRN
; print high/low
		ldd	,s
		addd	#32
		stb	VDP_REG
		sta	VDP_REG
		std	,s
		lda	#HIGHLOW_LEN
		bsr	W_PRINTSTRN
; print humidity
		ldd	,s
		addd	#32
		stb	VDP_REG
		sta	VDP_REG
		std	,s
		lda	#HUMIDITY_LEN
		bsr	W_PRINTSTRN
; print wind
		ldd	,s
		addd	#32
		stb	VDP_REG
		sta	VDP_REG
		lda	#WIND_LEN
		bsr	W_PRINTSTRN
; return
		puls	d
		puls	x
		leax	WEATHER_SIZE,x
		rts



W_PRINTSTRN:	ldb	,x+
		subb	#32
		stb	VDP_VRAM
		deca
		bne	W_PRINTSTRN
		rts

W_PRINTTEMP:	pshs	d		;save position
		lda	#4		;loop counter
		pshs	a
1$:		ldd	1,s		;set VRAM address
		stb	VDP_REG
		sta	VDP_REG
		bsr	W_PRINTDIGIT	;advance to next position
		ldd	1,s
		addd	#2
		std	1,s
		dec	,s		;loop
		bne	1$
		leas	3,s		;clean up and return
		rts

W_PRINTDIGIT:	pshs	d		;save position
		ldb	,x+		;get ASCII character
		cmpb	#0x20
		beq	W_BLANKDIGIT
		subb	#'0		;convert to index
		lslb			;multiply by 4
		lslb			;(4 patterns per character)
		addb	#0x60		;advance to start of digits
		stb	VDP_VRAM	;print upper left
		incb
		stb	VDP_VRAM	;print upper right
		incb
		pshs	b
		ldd	1,s		;get VRAM address
		addd	#32		;go to next row
		stb	VDP_REG		;set VRAM address
		sta	VDP_REG
		puls	b
		stb	VDP_VRAM	;print lower left
		incb
		stb	VDP_VRAM	;print lower right
		puls	d,pc

W_BLANKDIGIT:	clrb
		stb	VDP_VRAM
		stb	VDP_VRAM
		ldd	1,s
		addd	#32
		stb	VDP_REG
		sta	VDP_REG
		clrb
		stb	VDP_VRAM
		stb	VDP_VRAM
		puls	d,pc

W_PRINTICON:	pshs	d		;save position
		stb	VDP_REG
		sta	VDP_REG
		ldb	,x+		;get ASCII character
		subb	#'0		;convert to index
		lslb			;multiply by 16
		lslb			;(16 patterns per icon)
		lslb
		lslb
		addb	#0x90
		lda	#4		;4 rows of 4 patterns
1$:		stb	VDP_VRAM
		incb
		stb	VDP_VRAM
		incb
		stb	VDP_VRAM
		incb
		stb	VDP_VRAM
		incb
		pshs	d		;go to next row
		ldd	2,s
		addd	#32
		stb	VDP_REG
		sta	VDP_REG
		std	2,s
		puls	d
		deca			;advance loop counter
		bne	1$
		puls	d,pc

W_BLANKENTRY:	stb	VDP_REG
		sta	VDP_REG
		lda	#32*5
		clrb
1$:		stb	VDP_VRAM
		deca
		bne	1$
		leax	WEATHER_SIZE,x	;skip block
		rts

;;; retrieve weather data for all zipcodes
;;; arguments:	none
;;; returns:	WEATHERDATA array populated
;;; destroys:	A,B,X,Y
UPDATE:		ldx	#ZIPCODES
		ldy	#WEATHERDATA
		lda	#NUM_ZIPCODES
		pshs	a
updateloop:	tst	,x		;skip?
		beq	skipzipcode
		bsr	UPDATE_ZIPCODE
nextzipcode:	dec	,s
		bne	updateloop
		puls	a,pc

skipzipcode:	leax	ZIPCODE_LEN,x
		clr	,y		;blank weather data
		leay	WEATHER_SIZE,y
		bra	nextzipcode


;;; retrieve weather data for zipcode
;;; arguments:	pointer to zipcode in X
;;;		pointer to weather data struct in Y
;;; returns:	struct in Y populated
;;;		X and Y advanced
;;; destroys:	A,B,U
UPDATE_ZIPCODE:	pshs	x
		ldu	#URLBUF_ZIPCODE	;copy the zipcode into the URL string
		lda	#ZIPCODE_LEN
1$:		ldb	,x+
		stb	,u+
		deca
		bne	1$
		clrb
		stb	,u+		;null-terminate the string
		ldx	#URLBUF
		jsr	HTTP_GET_URL	;get URL contents into Y
		;jsr	foo
		puls	x
		leax	ZIPCODE_LEN,x
		rts

foo:		;sty	0xcd00
		lda	#110
		ldb	#'A
1$:		stb	,y+
		deca
		bne	1$
		rts

;------------------------------------------------------------------------------
; includes
;------------------------------------------------------------------------------

		.include "../include/httpser.asm"

;------------------------------------------------------------------------------
; static data
;------------------------------------------------------------------------------

; VDP register values
vdp_regs:	.fcb	0x02		;Graphics II
		.fcb	0x80		;Graphics II, display off
		.fcb	NAMETABLE/0x0400
		.fcb	(COLORTABLE/0x0040)|0b01111111
		.fcb	(PATTABLE/0x0800)|0b00000011
		.fcb	SPRATTABLE/0x0080
		.fcb	SPRPATTABLE/0x0800
		.fcb	0x00

; graphics patterns
GRAPHICS:	.include "graphics.inc"
GRAPHICS_END	.equ	.

; colors
COLORS:		.rept	12
		.fcb	0x21,0x21,0x21,0x21,0x21,0x21,0x21,0x21
		.fcb	0x21,0x21,0x21,0x21,0x21,0x21,0x21,0x21
		.fcb	0x31,0x31,0x31,0x31,0x31,0x31,0x31,0x31
		.fcb	0x31,0x31,0x31,0x31,0x31,0x31,0x31,0x31
		.endm

		.rept	16*8
		.fcb	0xB4
		.endm

		.rept	5*8
		.fcb	0xB4
		.endm
		.fcb	0xB4,0xB4,0xB4,0xB4,0xB4,0xB4,0xBF,0xBF
		.fcb	0xB4,0xB4,0xB4,0xB4,0xB4,0xF4,0xF4,0xF4
		.rept	8
		.fcb	0xF4
		.endm
		.fcb	0xB4,0xB4,0xB4,0xB4,0xB4,0xB4,0xB4,0xF4
		.fcb	0xFB,0xB5,0xFB,0xFB,0xFB,0xFB,0xFB,0xFB
		.fcb	0xF4,0xF4,0xF4,0xF4,0xF4,0xF4,0xF4,0xF4
		.fcb	0xF4,0xF4,0xF4,0xF4,0xF4,0xF4,0xF4,0xF4
		.rept	4*8
		.fcb	0xF4
		.endm

		; mostly cloudy
		.fcb	0xB5,0xB5,0xB5,0xB5,0xB5,0xB5,0xB5,0xB5
		.fcb	0xB5,0xB5,0xB5,0xB5,0xB5,0xB5,0xBF,0xBF
		.fcb	0xB5,0xB5,0xB5,0xB5,0xB5,0xB5,0xF5,0xF5
		.fcb	0xB5,0xB5,0xB5,0xB5,0xB5,0xB5,0xB5,0xB5
		.fcb	0xB5,0xB5,0xB5,0xB5,0xB5,0xF5,0xF5,0xF5
		.fcb	0xFB,0xFB,0xF5,0xF5,0xF5,0xF5,0xF5,0xF5
		.rept	10*8
		.fcb	0xF5
		.endm

		; cloudy
		.rept	16*8
		.fcb	0xFE
		.endm

		; rain
		.rept	4*8
		.fcb	0xE0
		.endm
		.rept	4
		.fcb	0xE0,0xE0,0xE0,0xE0,0xE0,0xE0,0x70,0x70
		.endm
		.rept	8*8
		.fcb	0x70
		.endm

		; thunderstorm
		.rept	4*8
		.fcb	0xE0
		.endm
		.fcb	0xE0,0xE0,0xE0,0xE0,0xB0,0xB0,0xB0,0xB0
		.fcb	0xE0,0xE0,0xE0,0xE0,0xE0,0xE0,0xE0,0xE0
		.fcb	0xE0,0xE0,0xE0,0xE0,0xE0,0xE0,0xE0,0xB0
		.fcb	0xE0,0xE0,0xE0,0xE0,0xE0,0xB0,0xB0,0xB0
		.rept	8*8
		.fcb	0xB0
		.endm

		;snow
		.rept	4*8
		.fcb	0xE0
		.endm
		.rept	4
		.fcb	0xE0,0xE0,0xE0,0xE0,0xE0,0xE0,0xF0,0xF0
		.endm
		.rept	8*8
		.fcb	0xF0
		.endm
COLORS_END	.equ	.

;------------------------------------------------------------------------------
; data structures
;------------------------------------------------------------------------------

ZIPCODES:	.ascii	"94403"
		.ascii	"94110"
		.ascii	"02879"
		.ascii	"15213"
ZIPCODES_END	.equ	.


WEATHERDATA:	.rmb	WEATHER_SIZE*NUM_ZIPCODES

URLBUF:		.ascii	"http://msarnoff.org/weather.cgi?zip="
URLBUF_ZIPCODE	.equ	.


