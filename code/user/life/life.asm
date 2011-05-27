; vim:noet:sw=8:ts=8:ai:syn=as6809
; Matt Sarnoff (msarnoff.org/6809) - November 30, 2010
;
; 9thlife
; a fancy implementation of Conway's Game of Life with fading, cycling colors
; and procedural sound effects
;
; Uses the "naive" computation method (neighbors computed for all cells,
; double-buffered grid) but I use some tricks and lots of loop unrolling to
; make it very fast; I believe it's around 50 generations per second.
; Edge wraparound is implemented as well.
;
; Since a new video frame is rendered every 1/60 of a second, the display is
; updated every other frame, and the CPU sits idle for the rest of the time.
;
; At such a small grid size, I'm not sure using different algorithms
; (storing neighbor counts, skipping dead cells with no neighbors) would make
; anything faster. The extra complexity would likely nullify any speed gain.
;
; The program can be controlled via serial terminal:
;   - slows down animation
;   = speeds up animation
;   R refreshes the field with random cell states
;   Q quits

	.nlist
	.include "../../rom/6809.inc"
	.include "../../rom/rom06.inc"
	.list

; VRAM addresses (for Graphics I)
SPRPATTABLE	.equ	0x0000
PATTABLE	.equ	0x0800
SPRATTABLE	.equ	0x1000
NAMETABLE	.equ	0x1400
COLORTABLE	.equ	0x2000

; grid dimensions, should be multiples of 2
GRID_COLS	.equ	32
GRID_ROWS	.equ	24
GRID_SIZE	.equ	GRID_COLS*GRID_ROWS

; number of patterns used to display a cell
; (fading in, fading out, colors, etc.)
CELL_STATES	.equ	128
CELL_PATTERNS	.equ	32
CELL_PATREPEATS	.equ	(CELL_STATES/CELL_PATTERNS)

; neighbor offsets
northwest	.equ	-GRID_COLS
north		.equ	northwest+1
northeast	.equ	north+1
east		.equ	2
southwest	.equ	GRID_COLS
south		.equ	southwest+1
southeast	.equ	south+1

	.area	_CODE(ABS)
	.org	USERPROG_ORG
;------------------------------------------------------------------------------
; setup
;------------------------------------------------------------------------------
		lds	#RAMEND+1	;set up stack pointer
		ldd	#VBLANK		;set up interrupt vector
		std	IRQVEC
		jsr	VDP_CLEAR	;clear VRAM
		ldx	#vdp_regs	;initialize VDP registers
		jsr	VDP_SET_REGS

; initialize sound
		ldd	#(PSG_CTRL<<8)|TONE_AB|NOISE_NONE
		std	PSG
		;ldd	#4000
		;jsr	PSG_SET_EFREQ
		ldd	#(PSG_A_AMPL<<8)|ENV_ENABLE
		std	PSG
		ldd	#(PSG_B_AMPL<<8)|ENV_ENABLE
		std	PSG

; write the cell graphics to the pattern table
		ldd	#(VRAM|PATTABLE)
		stb	VDP_REG
		sta	VDP_REG
		lda	#CELL_PATREPEATS
		pshs	a
loadcellpats:	ldx	#CELLPATS
		ldb	#CELL_PATTERNS
		jsr	VDP_LOADPATS
		dec	,s
		bne	loadcellpats
		puls	a

; write the character patterns to the pattern table
		ldx	#CHARS
		ldb	#14
		jsr	VDP_LOADPATS

; write the message to the name table in the bottom row, where it won't
; get overwritten
		ldx	#message
		ldd	#NAMETABLE+(32*23)+9
		jsr	VDP_PRINTSTR

; write the color table
		ldd	#(VRAM|COLORTABLE)
		stb	VDP_REG
		sta	VDP_REG
		ldx	#COLORS
		ldb	#4		;4*8 = 32 bytes written total
		jsr	VDP_LOADPATS

; initialize the life grids
		jsr	GRIDS_CLEAR
		ldx	#GRID2
		stx	NEXTGRID
		ldx	#GRID1
		stx	CURRENTGRID

; start with some random cells alive
		jsr	SETRANDOMSEED
		jsr	GRID_RANDOM

; initialize other parameters
		clr	ANIMFRAME
		lda	#10		;2 is the fastest speed possible
		bsr	SETANIMDELAY
		clr	LIVINGCELLS
		clr	DYINGCELLS
		clr	CTLRSTATE

; enable interrupts
		andcc	#0b11101111

; turn on the display, enable vertical blanking interrupt
		ldd	#0xE081		;set bits 6 and 5 of register 1
		sta	VDP_REG
		stb	VDP_REG
		bra	loop

;;; set animation delay and audio envelope generator frequency
;;; arguments:	delay in A
;;; returns:	none
;;; destroys:	B
SETANIMDELAY:	sta	ANIMDELAY
		clrb
		jmp	PSG_SET_EFREQ
	
;;; keypress routines
faster:		lda	ANIMDELAY
		deca
		bsr	SETANIMDELAY
		bra	loop

slower:		lda	ANIMDELAY
		inca
		bsr	SETANIMDELAY
		bra	loop

re_randomize:	jsr	GRID_RANDOM
		clr	ANIMFRAME
		bra	loop

;------------------------------------------------------------------------------
; logic update routine
;------------------------------------------------------------------------------
loop:		
; read controllers, we only care about button presses (not releases)
		jsr	READ_3BUTTON	;read controller 1
		tfr	a,b		;save controller 1 state
		coma			;detect only button presses
		ora	CTLRSTATE	;((NOT lastState) AND currentState)
		coma			;eval'd as (NOT ((NOT current) OR last))
		stb	CTLRSTATE	;save new controller state
; A now contains button deltas
		bita	#BTN_UP
		bne	faster
		bita	#BTN_DOWN
		bne	slower
		bita	#BTN_A|BTN_B|BTN_C
		bne	re_randomize

; perform animation
do_animate:	lda	ANIMFRAME
		cmpa	ANIMDELAY
		bhs	do_update	;only update grid after delay elapsed
		jmp	display

do_update:	clr	ANIMFRAME
; generate the next iteration
; X lags behind by one byte, it points to the current cell's west neighbor,
; letting us use indexed addressing with no offset (saves 1 cycle per cell)
; when reading the west neighbor
		ldx	CURRENTGRID
		jsr	GRID_BDRWRAP	;copy edges so wraparound works
		ldy	NEXTGRID
		ldu	#STATETABLE
		pshs	x,y
		leax	GRID_COLS,x
		leay	GRID_COLS+1,y

; the border cells are not updated, so instead of checking if each cell is at
; the border, we just unroll the entire row loop
; cell kernel is 58 cycles
; for 32x24 grid, 2 + ((30*58)+5+5+2+6)*22 = 38678 cycles (19.339 ms)
		lda	#GRID_ROWS-2	;skip top/bottom borders
updaterow:
	.rept GRID_COLS-2		;cell update kernel
		ldb	northwest,x	;compute live neighbor count
		addb	north,x		;(cells are either 0 or 1)
		addb	northeast,x
		addb	east,x
		addb	southwest,x
		addb	south,x
		addb	southeast,x
		addb	,x+		;west
		lslb
		addb	,x		;current cell state
		ldb	b,u		;get new cell state from table
		stb	,y+
	.endm
		leax	2,x		;skip left/right border cells
		leay	2,y
		deca
		lbne	updaterow
; now swap the grid pointers
		puls	x,y
		stx	NEXTGRID
		sty	CURRENTGRID

; play some sound
	.if 0
		clra
		ldb	LIVINGCELLS
		lslb
		rola
		lslb
		rola
		jsr	PSG_SET_AFREQ
		lda	DYINGCELLS
		clrb
		lsra
		rorb
		lsra
		rorb
		jsr	PSG_SET_BFREQ
		ldd	#(PSG_ENV_SHAPE<<8)|0b0
		std	PSG
	.endif
		ldx	#NOTES
		ldb	LIVINGCELLS
		lsrb
		lsrb
		lsrb
		andb	#0b00011110
		ldd	b,x
		jsr	PSG_SET_AFREQ
		ldb	DYINGCELLS
		comb
		lsrb
		lsrb
		lsrb
		andb	#0b00011110
		ldd	b,x
		jsr	PSG_SET_BFREQ
		ldd	#(PSG_ENV_SHAPE<<8)|0b0
		std	PSG
		clr	LIVINGCELLS
		clr	DYINGCELLS


; update the display grid, causing cells to dissolve in and out,
; and fade between colors
display:	ldu	CURRENTGRID
		ldy	#DISPLAYGRID
		ldx	#GRID_SIZE
updatedisp:	ldb	,u+		;is cell alive or dead?
		beq	cell_dead
cell_alive:	ldb	,y		;is pattern at max?
		cmpb	#CELL_STATES-1
		beq	nextcell	;yes, keep it there
		incb			;no, increment it
		inc	LIVINGCELLS
		bra	nextcell

cell_dead:	ldb	,y		;is pattern zero?
		beq	nextcell	;yes, keep it there
		decb			;no, decrement it
		inc	DYINGCELLS

nextcell:	stb	,y+
		leax	-1,x
		bne	updatedisp

		sync
		jmp	loop



;------------------------------------------------------------------------------
; vertical blanking interrupt handler
;------------------------------------------------------------------------------
VBLANK:		lda	VDP_REG		;read status, clear interrupt flag
; load the name table with the new grid
; don't need to write the top border row, so we set the VRAM address
; to just before the start of row 1
		ldd	#(VRAM|(NAMETABLE+GRID_COLS-1))	;skip top row
		stb	VDP_REG
		sta	VDP_REG
		ldu	#DISPLAYGRID
; advance to the byte before the first byte of row 1
; (this is the right border of row 0)
		leau	GRID_COLS-1,u	;skip top row
; stack-blast the new grid into VRAM, blanking out the border columns
; (pulu d is faster than ldd ,u++)
		ldx	#VDP_VRAM
		ldb	#GRID_ROWS-2	;don't need top or bottom borders
		pshs	b
1$:		pulu	d		;skip the 2 border bytes
		ldd	#0		;and write zeros in their place
		sta	,x
		stb	0,x		;extra cycle added so VDP doesn't miss
	.rept (GRID_COLS/2)-1
		pulu	d		;now blast the cells
		sta	,x
		stb	0,x
	.endm
		dec	,s		;decrement row counter
		bne	1$
		puls	b
		inc	ANIMFRAME
		rti



;------------------------------------------------------------------------------
; subroutines
;------------------------------------------------------------------------------

;;; clear all grids (state grid 1, state grid 2, display grid)
;;; arguments:	none
;;; returns:	none
;;; destroys:	X,U,A,B
GRIDS_CLEAR:	ldx	#GRID1
		ldd	#(GRID_SIZE*3)/2	;number of words
		ldu	#0
1$:		stu	,x++
		subd	#1
		bne	1$
		rts


;;; initialize CURRENTGRID with random cells alive
;;; arguments:	none
;;; returns:	none
;;; destroys:	X,A,B
GRID_RANDOM:	ldx	CURRENTGRID
		leax	GRID_COLS+1,x	;skip top/left border
		ldb	#GRID_ROWS-2	;row counter at 1,s
		pshs	d
;---- row loop
randrowloop:	lda	#GRID_COLS-2	;column counter at ,s
		sta	,s
;-------- column loop
randcolloop:	jsr	RANDBIT		;get random bit
		rolb			;extend carry bit to byte
		andb	#1
		stb	,x+		;write byte
		dec	,s
		bne	randcolloop
;-------- end column loop
		leax	2,x		;skip border bytes
		dec	1,s
		bne	randrowloop
;---- end row loop
		puls	d,pc


;;; copy cells at borders to opposite sides, to handle wrap-around
;;; (toroidal world)
;;; arguments:	grid pointer in X
;;; returns:	none
;;; destroys:	A,B
;;;
;;; example:
;;;   - - - - - - -      - h i j k l -
;;;   - a b c d e -      e a b c d e a
;;;   - f       g -  =>  g f       g f
;;;   - h i j k l -      l h i j k l h
;;;   - - - - - - -      - a b c d e -
GRID_BDRWRAP:	pshs	x,y			;save pointers
; not too many cells need to be copied... why don't we unroll the whole thing?
; top row -> bottom row
; x runs along top row
; y runs along bottom row
		leay	GRID_COLS*(GRID_ROWS-2),x
		leax	GRID_COLS,x
		n = 1
	.rept (GRID_COLS-2)/2
		ldd	n,x			;copy top row to bottom
		std	n+GRID_COLS,y
		ldd	n,y			;copy bottom row to top
		std	n-GRID_COLS,x
		n = n+2
	.endm

; left -> right, right -> left
; note: x now points to column 0, row 1
	.rept (GRID_ROWS-2)
		sta	,x
		lda	1,x			;copy left to right
		sta	GRID_COLS-1,x
		lda	GRID_COLS-2,x		;copy right to left
		sta	,x
		leax	GRID_COLS,x		;advance to next row
	.endm
		puls	x,y,pc


	.include "../include/random.asm"
	.include "../include/ym2149.asm"

;------------------------------------------------------------------------------
; static data
;------------------------------------------------------------------------------

; VDP register values
vdp_regs:	.fcb	0x00			;Graphics I
		.fcb	0x80			;Graphics I, 16K, display off
		.fcb	NAMETABLE/0x0400
		.fcb	COLORTABLE/0x0040
		.fcb	PATTABLE/0x0800
		.fcb	SPRATTABLE/0x0080
		.fcb	SPRPATTABLE/0x0800
		.fcb	0x01			;black background

; patterns
CELLPATS:	.include "cells32.inc"
CELLPATS_END	.equ	.

CHARS:		.include "chars.inc"
CHARS_END	.equ	.

COLORS:		.fcb	0x40,0x40,0x40,0x40
		.fcb	0x24,0x24,0x24,0x24
		.fcb	0xB2,0xB2,0xB2,0xB2
		.fcb	0x8B,0x8B,0x8B,0x8B
		.fcb	0xE0,0xE0,0xE0,0xE0
		.fcb	0,0,0,0,0,0,0,0
		.fcb	0,0,0,0,0,0,0,0
COLORS_END	.equ	.

; about message
message:	.fcb	0x80,0x81,0x82,0x83,0x84,0x85,0x86
		.fcb	0x87,0x88,0x89,0x8a,0x8b,0x8c,0x8d,0x00

; cell state transition table
; bit 0: alive/dead, bits 4-1: number of neighbors
STATETABLE:	.fcb	0		;0b00000 (dead,  0 neighbors)
		.fcb	0		;0b00001 (alive, 0 neighbors)
		.fcb	0		;0b00010 (dead,  1 neighbor)
		.fcb	0		;0b00011 (alive, 1 neighbor)
		.fcb	0		;0b00100 (dead,  2 neighbors)
		.fcb	1		;0b00101 (alive, 2 neighbors)
		.fcb	1		;0b00110 (dead,  3 neighbors)
		.fcb	1		;0b00111 (alive, 3 neighbors)
		.fcb	0		;0b01000 (dead,  4 neighbors)
		.fcb	0		;0b01001 (alive, 4 neighbors)
		.fcb	0		;0b01010 (dead,  5 neighbors)
		.fcb	0		;0b01011 (alive, 5 neighbors)
		.fcb	0		;0b01100 (dead,  6 neighbors)
		.fcb	0		;0b01101 (alive, 6 neighbors)
		.fcb	0		;0b01110 (dead,  7 neighbors)
		.fcb	0		;0b01111 (alive, 7 neighbors)
		.fcb	0		;0b10000 (dead,  8 neighbors)
		.fcb	0		;0b10001 (alive, 8 neighbors)

; note frequencies
NOTES:		;.fdb	35,39,47,53,59
		;.fdb	71,79,94,106,119
		.fdb	142,159,189,212,238
		.fdb	284,318,379,425,477
		.fdb	568,637,758,851,955
		.fdb	1136;,1275,1516,1702,1911
		;.fdb	1911,1911


;------------------------------------------------------------------------------
; variables
;------------------------------------------------------------------------------

; two grid buffers for cell state
; each entry is either 0 (dead) or 1 (alive)
GRID1:		.rmb	GRID_SIZE
GRID2:		.rmb	GRID_SIZE

; visual representation of the cells (name table)
DISPLAYGRID:	.rmb	GRID_SIZE

CURRENTGRID:	.rmb	2		;pointer to GRID1 or GRID2
NEXTGRID:	.rmb	2		;pointer to GRID1 or GRID2
ANIMFRAME:	.rmb	1		;current frame counter
ANIMDELAY:	.rmb	1		;frames per life iteration

; counters used for sound generation
LIVINGCELLS:	.rmb	1
DYINGCELLS:	.rmb	1

CTLRSTATE:	.rmb	1		;controller state
