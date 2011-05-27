; vim:noet:sw=8:ts=8:ai:syn=as6809
; Matt Sarnoff (msarnoff.org/6809) - November 13, 2010
;
; TMS9918 text mode "hello world"
; Adapted from sample code on the N8VEM website

	.nlist
	.include "../../rom/6809.inc"
	.include "../../rom/rom06.inc"
	.list

	.area	_CODE(ABS)
	.org	USERPROG_ORG
		lds	#RAMEND+1	;set up stack pointer

		ldb	#LED_GREEN
		jsr	UART_SETLED

		jsr	VDP_INITTEXT

;copy character set to VRAM at 0x0800
		ldd	#(VRAM|0x0800)	;write VRAM address
		stb	VDP_REG		;low byte first
		sta	VDP_REG		;then high byte

		ldx	#TEXTFONT	;copy 128 characters of font
		ldb	#128
		jsr	VDP_LOADPATS
		;ldx	#TEXTFONT	;copy inverse video characters
		;ldb	#128
		;jsr	VDP_LOADIPATS


; print some strings
		ldd	#0x0000		;line 1
		ldx	#str1
		jsr	VDP_PRINTSTR
		ldd	#0x0028		;line 2
		jsr	VDP_PRINTSTR
		ldd	#0x0050		;line 3
		jsr	VDP_PRINTSTR
		ldd	#0x0078		;line 4
		jsr	VDP_PRINTSTR


; then the full character set
		ldd	#(VRAM|0x00C8)	;line 6
		stb	VDP_REG
		sta	VDP_REG
		
		ldb	#128
1$:		stb	VDP_VRAM
		incb
		bne	1$

; turn on the display
		ldd	#0xD081		;set bit 6 of register 1
		sta	VDP_REG
		stb	VDP_REG


; aaaaaand we're done
		bra	.


; strings
str1:		.asciz	"Ultim809 8-Bit Computer"
str2:		.asciz	"By Matt Sarnoff"
str3:		.asciz	"www.msarnoff.org"
str4:		.asciz	"November 14, 2010"


