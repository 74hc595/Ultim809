; vim:noet:sw=8:ts=8:ai:syn=as6809
; Matt Sarnoff (msarnoff.org/6809) - May 13, 2010
;
; Plasma effect.

	.nlist
	.include "../../rom/6809.inc"
	.include "../../rom/rom06.inc"
	.list

	;.define SOUND

; VRAM addresses (for Graphics I)
SPRPATTABLE	.equ	0x0000
PATTABLE	.equ	0x0800
SPRATTABLE	.equ	0x1000
NAMETABLE	.equ	0x1400
COLORTABLE	.equ	0x2000

; Parameters
GRID_WIDTH	.equ	32
GRID_HEIGHT	.equ	34
GRID_SIZE	.equ	GRID_WIDTH*GRID_HEIGHT
NUM_COLORS	.equ	8

;------------------------------------------------------------------------------
; variables
;------------------------------------------------------------------------------

; variables in direct page
VARSTART	.equ	0x80

; grid pointers
CURRENTGRID	.equ	VARSTART	;pointer to GRID1 or GRID2
NEXTGRID	.equ	VARSTART+2	;pointer to GRID1 or GRID2

T		.equ	VARSTART+5
T_3		.equ	VARSTART+6
DIV3_COUNT	.equ	VARSTART+7
SIN_T		.equ	VARSTART+8
SIN_T_3		.equ	VARSTART+9

; evaluation function pointer
PLASMA_FN	.equ	VARSTART+10

; temporary values usable by computation functions
TEMP1		.equ	VARSTART+12
TEMP2		.equ	VARSTART+13

;------------------------------------------------------------------------------
; setup
;------------------------------------------------------------------------------
	.area	_CODE(ABS)
	.org	USERPROG_ORG
		lds	#RAMEND+1	;set up stack pointer
		ldd	#VBLANK		;set up interrupt vector
		std	IRQVEC
		jsr	VDP_CLEAR	;clear VRAM
		ldx	#vdp_regs	;initialize VDP registers
		jsr	VDP_SET_REGS

; set up the pattern table
		ldd	#(VRAM|PATTABLE)
		stb	VDP_REG
		sta	VDP_REG
		lda	#NUM_COLORS	;write 8 copies of the cell patterns
		pshs	a
loadcellpats:	ldx	#CELLPATS
		ldb	#16
		jsr	VDP_LOADPATS
		dec	,s
		bne	loadcellpats
		puls	a

; set up the color table
		ldd	#(VRAM|COLORTABLE)
		stb	VDP_REG
		sta	VDP_REG
		ldx	#COLORS
		ldb	#2		;2*8 = 16 bytes
		jsr	VDP_LOADPATS

; set up variables
		ldd	#GRID1
		std	*CURRENTGRID
		ldd	#GRID2
		std	*NEXTGRID
		clr	*T
		clr	*T_3
		lda	#3
		sta	*DIV3_COUNT
		ldd	#WAVE2
		std	*PLASMA_FN

	.ifdef	SOUND
; set up sound
		ldd	#(PSG_CTRL<<8)|TONE_AB|NOISE_NONE
		std	PSG
		ldd	#(PSG_A_AMPL<<8)|15;ENV_ENABLE
		std	PSG
		ldd	#(PSG_B_AMPL<<8)|15;ENV_ENABLE
		std	PSG

		ldd	#(PSG_ENV_SHAPE<<9)|8
		std	PSG
	.endif

; enable interrupts
		andcc	#0b11101111

; turn on the display, enable vertical blanking interrupt
		ldd	#0xE081		;set bits 6 and 5 of register 1
		sta	VDP_REG
		stb	VDP_REG
		jmp	loop


;------------------------------------------------------------------------------
; logic update routine
;------------------------------------------------------------------------------
loop:	
; iterate and generate NEXTGRID
		ldy	*NEXTGRID
		ldd	#(32<<8)|24	;initialize x and y counters
		pshs	d

		ldu	#SIN8
		ldd	*T		;take sin of T and T/3
		lda	a,u
		ldb	b,u
		std	*SIN_T

; x is in ,s and y is in 1,s
yloop:
;---- inner loop
		lda	#32
		sta	,s
;-------- calculation
xloop:		jmp	[PLASMA_FN]
setcell:	anda	#0b01111111
		sta	,y+
;-------- end calculation
		dec	,s
		bne	xloop
;---- end inner loop
		dec	1,s
		bne	yloop

; advance timers
		inc	*T
		dec	*DIV3_COUNT
		bne	flipbuffers
		inc	*T_3

; flip buffers
flipbuffers:	ldx	*CURRENTGRID
		ldu	*NEXTGRID
		stu	*CURRENTGRID
		stx	*NEXTGRID

	.ifdef	SOUND
; update sound
		;lda	#0x03
		clrb
		ldx	#GRID1
		;ldb	*SIN_T_3
		lda	,x
		jsr	PSG_SET_AFREQ

		lda	#0x00
		ldx	#GRID1+400
		;ldb	*SIN_T
		ldb	,x
		negb
		jsr	PSG_SET_BFREQ

		;ldb	*SIN_T_3
		;ldb	GRID1+234
		;lda	#1
		;jsr	PSG_SET_EFREQ
	.endif
		sync
		jmp	loop


;------------------------------------------------------------------------------
; cell evaluator functions
;------------------------------------------------------------------------------
; x coordinate in ,s (0-32)
; y coordinate in 1,s (0-23)
; sin table pointer in u
; return value in a
; do not rts, branch to setcell

GRADIENT:	lda	,s
		adda	1,s
		adda	*T
		bra	setcell

MUNCHING:	lda	,s
		deca
		eora	1,s
		adda	*T
		bra	setcell

WAVE:		lda	,s
		adda	*T
		ldu	#SIN8
		lda	a,u
		adda	1,s
		suba	*T
		lda	a,u
		bra	setcell

WAVE2:		lda	,s		;first component, sin(y)
		adda	*T_3
		lda	a,u
		adda	*T
		;lsla
		lda	a,u
		sta	*TEMP1

		lda	1,s
		adda	*T
		lda	a,u
		adda	*T_3
		;lsla
		lda	a,u

		adda	*TEMP1
		bra	setcell

		


;------------------------------------------------------------------------------
; vertical blanking interrupt handler
;------------------------------------------------------------------------------
VBLANK:		lda	VDP_REG		;read status, clear interrupt flag
; copy the grid into the name table
		ldd	#(VRAM|NAMETABLE)
		stb	VDP_REG
		sta	VDP_REG
		ldu	*CURRENTGRID
		ldx	#VDP_VRAM
; stack-blast the grid into VRAM (pulu d is faster than ldd ,u++)
	.rept	16*24		;unroll that shit
		pulu	d
		sta	,x
		stb	0,x		;extra cycle added so VDP doesn't miss
	.endm
		rti		
	

;------------------------------------------------------------------------------
; subroutines
;------------------------------------------------------------------------------


;------------------------------------------------------------------------------
; includes
;------------------------------------------------------------------------------

	.include "../include/random.asm"
	.include "../include/ym2149.asm"


;------------------------------------------------------------------------------
; static data
;------------------------------------------------------------------------------

; VDP register values
vdp_regs:	.fcb	0x00	;Graphics I
		.fcb	0x80	;Graphics I, 16K, display off, no sprites
		.fcb	NAMETABLE/0x0400
		.fcb	COLORTABLE/0x0040
		.fcb	PATTABLE/0x0800
		.fcb	SPRATTABLE/0x0080
		.fcb	SPRPATTABLE/0x0800
		.fcb	0x01	;black background

; trig tables
		.include "sin8.inc"
;COS8:		.include "cos8.inc"

; cell graphics
CELLPATS:	.include "cells16.inc"
CELLPATS_END	.equ	.

; color order:
; medium red (0x8)
; light red (0x9)
; light yellow (0xB)
; light green (0x3)
; cyan (0x7)
; light blue (0x5)
; dark blue (0x4)
; magenta (0xD)
COLORS:		.fcb	0x98,0x98
		.fcb	0xB9,0xB9
		.fcb	0x3B,0x3B
		.fcb	0x73,0x73
		.fcb	0x57,0x57
		.fcb	0x45,0x45
		.fcb	0xD4,0xD4
		.fcb	0x8D,0x8D

;------------------------------------------------------------------------------
; data structures
;------------------------------------------------------------------------------

; two grid buffers
GRID1:		.rmb	GRID_SIZE
GRID2:		.rmb	GRID_SIZE

