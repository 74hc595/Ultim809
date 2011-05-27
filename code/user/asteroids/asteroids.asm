; vim:noet:sw=8:ts=8:ai:syn=as6809
; Matt Sarnoff (msarnoff.org/6809) - May 5, 2010
;
; SPACE ROCKS IN SPACE!
; An asteroids clone.

	.nlist
	.include "../../rom/6809.inc"
	.include "../../rom/rom06.inc"
	.list

	;.define	ONE_BULLET
	
; VRAM addresses (for Graphics I)
SPRPATTABLE	.equ	0x0000
PATTABLE	.equ	0x0800
SPRATTABLE	.equ	0x1000
NAMETABLE	.equ	0x1400
COLORTABLE	.equ	0x2000

; Parameters
MAX_LG_ASTS	.equ	6
NUM_ASTEROIDS	.equ	MAX_LG_ASTS*6
NUM_SCRBULLETS	.equ	2	;saucer bullets

	.ifdef ONE_BULLET
NUM_SHIPBULLETS	.equ	1
	.else
NUM_SHIPBULLETS	.equ	4
	.endif


AST_LG_SIZE	.equ	16
AST_MED_SIZE	.equ	12
AST_SM_SIZE	.equ	8
SHIP_SIZE	.equ	16
EXPLOSION_SIZE	.equ	16
SAUCER_LG_SIZE	.equ	14
SAUCER_SM_SIZE	.equ	10
EXTRA_LIFE_AMT	.equ	0x10	;BCD thousands (10000)

; Object structure offsets
life		.equ	0
type		.equ	1
xpos		.equ	2	;x and y are 8.8 fixed-point
xpos_int	.equ	2
xpos_frac	.equ	3
ypos		.equ	4
ypos_int	.equ	4
ypos_frac	.equ	5
xvel		.equ	6	;x and y velocities are 8.8 fixed point
yvel		.equ	8
pattern		.equ	10
siz		.equ	11
OBJ_SIZE	.equ	12

; Object types
; Lower 2 bits of bullet type indicate owner
saucer		.equ	1
player1		.equ	2
player2		.equ	3
player_mask	.equ	2
owner_mask	.equ	3
bullet		.equ	8
asteroid	.equ	16

;------------------------------------------------------------------------------
; variables
;------------------------------------------------------------------------------

; Put all game variables in the direct page
VARSTART	.equ	0x80

; Temporary storage
TEMP1		.equ	VARSTART
TEMP2		.equ	VARSTART+1
TEMP3		.equ	VARSTART+2
TEMP4		.equ	VARSTART+3

ATTRACTMODE	.equ	VARSTART+4
SCORE		.equ	VARSTART+5	;4 BCD digits (0-99990)
SCORE_MSB	.equ	VARSTART+5
SCORE_LSB	.equ	VARSTART+6
LIVES		.equ	VARSTART+7	;player lives
NEXT_LIFE_AT	.equ	VARSTART+8
RESPAWN_TIMER	.equ	VARSTART+9
NEW_LEVEL_TIMER	.equ	VARSTART+10
THUMP_TIMER	.equ	VARSTART+11
THUMP_PITCH	.equ	VARSTART+12
LIFESND_TIMER	.equ	VARSTART+13
START_ASTEROIDS	.equ	VARSTART+14	;number of asteroids at level start
ASTEROIDS_LEFT	.equ	VARSTART+15	;number of asteroids left
FRAMECOUNTER	.equ	VARSTART+16
PAD1STATE	.equ	VARSTART+17
PAD2STATE	.equ	VARSTART+18
PREVPAD1STATE	.equ	VARSTART+19
PREVPAD2STATE	.equ	VARSTART+20
NEXT_AST_PTR	.equ	VARSTART+21	;2 bytes
SHIPANGLE	.equ	VARSTART+23
HYPERSPACE	.equ	VARSTART+24	;ship is in hyperspace
SAUCER_TIMER	.equ	VARSTART+25	;time until next saucer
NEXT_SAUCER_INT	.equ	VARSTART+26	;next interval between saucers
LARGE_SAUCERS	.equ	VARSTART+27	;large saucers left
NEXT_LG_SAUCERS	.equ	VARSTART+28	;next number of large saucers

; Display actions
DISPLAY_ACTION	.equ	VARSTART+29
printerror	.equ	1
printstart	.equ	2
printgameover	.equ	3
clearstrings	.equ	4

; Sound
; Channel A:	ship and saucer firing sounds
; Channel B:	background sounds
; Channel C:	explosions

SNDPTR		.equ	VARSTART+30	;2 bytes
SAUCERSNDPTR	.equ	VARSTART+32	;2 bytes
BGSOUND_BITS	.equ	VARSTART+34
lifesnd		.equ	0x80	;extra life sound has highest priority
saucersnd	.equ	0x40	;then saucer sound
thrustsnd	.equ	0x20	;then thrust sound
thumpsnd	.equ	0x10	;then thump sound

ERROR_MSG_PTR	.equ	VARSTART+35	;2 bytes


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
		jsr	SETRANDOMSEED
		lda	CTLR_SET_SELECT

; write the sprite patterns to VRAM
		ldd	#(VRAM|SPRPATTABLE)
		stb	VDP_REG
		sta	VDP_REG
		ldx	#SPRITEPATS
		clrb			;B=0 -> 256 patterns (2048 bytes)
		jsr	VDP_LOADPATS

; write the text patterns to VRAM
		ldd	#(VRAM|PATTABLE+(32*8))
		stb	VDP_REG
		sta	VDP_REG
		ldx	#TEXTPATS
		ldb	#64
		jsr	VDP_LOADPATS
		ldd	#(VRAM|PATTABLE)
		stb	VDP_REG
		sta	VDP_REG
		lda	#0
		ldx	#8
		jsr	VDP_FILL		

; clear the color table
		ldd	#(VRAM|COLORTABLE)
		stb	VDP_REG
		sta	VDP_REG
		lda	#0xF0
		ldx	#32
		jsr	VDP_FILL

; write to the name table
		ldx	#authorstr
		jsr	VDP_PRINTPSTR

; initialize sound effects
		ldx	#MUTE
		stx	*SNDPTR
		clr	*SAUCERSNDPTR
		ldd	#(PSG_CTRL<<8)|TONE_AB|NOISE_C
		std	PSG
		ldd	#(PSG_C_AMPL<<8)|ENV_ENABLE
		std	PSG
		ldd	#10000
		jsr	PSG_SET_EFREQ

; set up attract mode
		jsr	CLR_OBJECTS	;clear everything first
		clr	*HYPERSPACE
		ldb	#4		;put some asteroids up
		jsr	AST_NEW_SET
		clr	*FRAMECOUNTER
		ldd	#0
		std	*SCORE		;no score, no lives
		sta	*LIVES
		sta	*RESPAWN_TIMER	;turn off timers
		sta	*NEW_LEVEL_TIMER
		sta	*SAUCER_TIMER
		sta	*BGSOUND_BITS
		inca
		sta	*ATTRACTMODE
		lda	#printstart
		sta	*DISPLAY_ACTION

; enable interrupts
		andcc	#0b11101111

; turn on the display, enable vertical blanking interrupt
		ldd	#0xE281		;set bits 6 and 5 of register 1
		sta	VDP_REG
		stb	VDP_REG
		jmp	loop



;------------------------------------------------------------------------------
; controller input routines
;------------------------------------------------------------------------------

rotateleft:	ldb	*SHIPANGLE
		incb
storeshipangle:	andb	#0b00011111
		stb	*SHIPANGLE
		bra	checkthrust

rotateright:	ldb	*SHIPANGLE
		decb
		bra	storeshipangle

thrust:		ldu	#TRIGTABLE	;get thrust vector
		ldb	*SHIPANGLE
		lslb
		lslb
		leau	b,u		;get entry in trig table
		ldd	,u++		;get cosine value
		asra			;divide by 4
		rorb
		asra
		rorb
		addd	PLAYERSHIP+xvel	;add to x velocity component
		std	PLAYERSHIP+xvel
		ldd	,u		;get sine value
		asra			;divide by 4
		rorb
		asra
		rorb
		addd	PLAYERSHIP+yvel	;add to y velocity component
		std	PLAYERSHIP+yvel
		jsr	THRUSTSND_ON
		bra	checkfire
	
fire:		
	.ifndef ONE_BULLET
		ldb	*PREVPAD1STATE
		bitb	#BTN_B
		bne	gameinpdone
	.endif
		jsr	GET_BULLET	;find an available bullet
		beq	gameinpdone	;Z flag set if no bullets available
		ldy	#PLAYERSHIP	;pointer to object firing the bullet
		ldb	*SHIPANGLE	;bullet angle
		jsr	FIRE_BULLET	;fire bullet
		ldd	#SHIPFIRE
		std	*SNDPTR
		bra	checkhyper

hyperspace:	clr	PLAYERSHIP+life	;disappear ship
		jsr	RANDBYTE	;will hyperspace kill?
		orb	#0b11111000	;1 in 8 chance
		stb	*HYPERSPACE
		lda	#0x30		;enable random position spawn
		sta	*RESPAWN_TIMER
		bra	gameinpdone

GAME_INPUT:	ldb	*FRAMECOUNTER	;read left/right/up every other frame
		bitb	#0b00000001
		bne	checkfire
		bita	#BTN_LEFT
		bne	rotateleft
		bita	#BTN_RIGHT
		bne	rotateright
checkthrust:	ldb	*FRAMECOUNTER
		bitb	#0b00000011	;read thrust button every 4th frame
		bne	gameinpdone
		bita	#BTN_UP
		bne	thrust
checkfire:	lda	*PAD1STATE
		bita	#BTN_B
		bne	fire
checkhyper:	lda	*PAD1STATE
		bita	#BTN_C
		bne	hyperspace
gameinpdone:	rts

;------------------------------------------------------------------------------
; timer response routines
;------------------------------------------------------------------------------
; new level timer
CHECK_TIMERS:	tst	*NEW_LEVEL_TIMER ;new level?
		beq	chkrespawn	;timer is 0, so no
		dec	*NEW_LEVEL_TIMER ;timer is 1? yes
		beq	startnewlevel

; respawn player timer
chkrespawn:	lda	*RESPAWN_TIMER	;need to respawn the player?
		beq	chksaucer	;timer is 0, so no
		cmpa	#1
		beq	respawn		;timer is 1, try to respawn
		dec	*RESPAWN_TIMER	;timer is > 1, decrement timer
		bra	chksaucer

startnewlevel:	ldb	*START_ASTEROIDS	;next level has 1 more asteroid
		incb
		cmpb	#MAX_LG_ASTS
		blo	newastset
		ldb	#MAX_LG_ASTS
newastset:	stb	*START_ASTEROIDS
		jsr	AST_NEW_SET
		lda	#240		;first saucer after 8 seconds
		sta	*NEXT_SAUCER_INT
		sta	*SAUCER_TIMER
		lda	*NEXT_LG_SAUCERS ;set number of large saucers
		sta	*LARGE_SAUCERS
		clr	*NEW_LEVEL_TIMER
		jsr	THUMPSND_ON	;play thump sound
		bra	chkrespawn

respawn:	tst	*LIVES		;can't respawn with zero lives
		beq	chksaucer
		jsr	SHIP_CAN_SPAWN	;is it safe to respawn?
		bne	chksaucer	;if not, try again next frame
		jsr	THUMPSND_ON	;play thump sound
		clr	*RESPAWN_TIMER
		lda	*NEXT_SAUCER_INT ;reset saucer timer
		sta	*SAUCER_TIMER
		jsr	SHIP_INIT	;the ship might die here if in hypersp.
		clr	*HYPERSPACE

chksaucer:	ldb	*FRAMECOUNTER	;update countdown every other frame
		bitb	#0b00000001
		bne	timersdone
		tst	*SAUCER_TIMER	;is timer zero?
		beq	timersdone	;if so, don't update
		dec	*SAUCER_TIMER	;decrement saucer counter
		bne	timersdone	;greater than 0? do nothing
		jsr	SAUCER_INIT	;0 now? spawn a saucer

timersdone:	rts

;------------------------------------------------------------------------------
; logic update routine
;------------------------------------------------------------------------------
loop:	
; update timers
		bsr	CHECK_TIMERS

; update thump sound effect
thumpupdate:	jsr	THUMP_UPDATE

; read controllers
chkinput:	jsr	THRUSTSND_OFF	;turn off thrust sound
		lda	*PAD1STATE
		tst	*ATTRACTMODE	;attract mode?
		bne	attractinput	;yes, wait for start button
		tst	PLAYERSHIP+life
		bpl	updatesaucer	;don't read game controls if dead
		jsr	GAME_INPUT	;no, read game controls
		bra	updateship	;player is alive, update ship

; attract mode input, wait for button
attractinput:	bita	#BTN_START	;start button pressed?
		lbeq	updatesaucer	;no, skip directly to object update
		jsr	NEW_GAME	;otherwise, start game
		jmp	updatesaucer

; update ship state (skipped if player is dead)
updateship:	ldb	*SHIPANGLE	;update ship sprite
		lslb			;multiply by 4 to get sprite number
		lslb
		addb	#SPR_SHIP	;add sprite offset
		stb	PLAYERSHIP+pattern
		ldx	#PLAYERSHIP+xvel
		jsr	DECELERATE
		leax	2,x
		jsr	DECELERATE

; update saucer
updatesaucer:	tst	SAUCER+life	;saucer alive?
		bpl	astcoll		;no, skip
		lda	SAUCER+xpos	;reached edge of screen?
		tst	SAUCER+xvel	;moving left or right?
		bmi	movingleft
movingright:	cmpa	#253		;off right edge?
		blo	keeponscreen
		bra	removesaucer
movingleft:	cmpa	#2		;off left edge?
		bls	removesaucer
keeponscreen:	jsr	SAUCER_ACTION	;move and/or fire
		bra	astcoll

removesaucer:	clr	SAUCER+life	;remove saucer
		jsr	SAUCERSND_OFF	;stop sound
		jsr	SAUCER_NEXT	;set up the next one

; ship/saucer -> asteroid collision detection
astcoll:	ldx	#SAUCER
astcolloop:	tst	life,x		;skip dead/dying objects
		bpl	nextast

astshipcoll:	tst	PLAYERSHIP+life	;player alive?
		bpl	astsaucercoll	;no, skip
		ldy	#PLAYERSHIP
		jsr	OBJ_OBJ_COLL
astsaucercoll:	cmpx	#SAUCER		;don't compare saucer to saucer
		beq	nextast
		tst	SAUCER+life	;saucer alive?
		bpl	nextast		;no, skip
		ldy	#SAUCER
		jsr	OBJ_OBJ_COLL

nextast:	leax	OBJ_SIZE,x
		cmpx	#ASTEROIDS_END
		bne	astcolloop

; bullet -> ship/saucer/asteroid collision detection
		pshs	a		;temporary for bullet owner
		ldy	#BULLETS
bulletloop:	tst	life,y		;skip dead bullets
		beq	nextbullet
		lda	type,y		;get bullet owner
		anda	#owner_mask
		sta	,s		;save bullet owner
;---- inner loop
		ldx	#PLAYERSHIP
objcolloop:	tst	life,x		;skip dead/dying objects
		bpl	nextcollobj
		lda	type,x		;bullets can't kill their owners
		cmpa	,s
		beq	nextcollobj	;skip if this object owns the bullet
		jsr	BULLET_COLL
		tst	life,y		;might have killed the bullet
		beq	nextbullet
nextcollobj:	leax	OBJ_SIZE,x
		cmpx	#OBJECTS_END
		bne	objcolloop
;---- end inner loop
nextbullet:	leay	OBJ_SIZE,y
		cmpy	#BULLETS_END
		bne	bulletloop
		puls	a		;clean up temporary
; move objects
updateobjects:	ldx	#OBJECTS
objloop:	tst	life,x		;skip dead objects
		beq	nextobj
		bsr	OBJ_MOVE	;add velocity to position
		bsr	OBJ_BOUNDSCHK	;handle wraparound
		bsr	OBJ_UPDATELIFE	;decrement life counter if necessary
nextobj:	leax	OBJ_SIZE,x
		cmpx	#OBJECTS_END
		bne	objloop

; advance frame counter and save controller state
		inc	*FRAMECOUNTER
		ldd	*PAD1STATE
		std	*PREVPAD1STATE

; update sound effects
		jsr	SND_UPDATE
		sync
		jmp	loop
		


THUMP_UPDATE:	dec	*THUMP_TIMER
		bne	nothumpreset
		lda	*ASTEROIDS_LEFT
		lsla
		adda	#10
		cmpa	#60
		blo	setthtimer
		lda	#60
setthtimer:	sta	*THUMP_TIMER
		com	*THUMP_PITCH
nothumpreset:	rts

;;; update position of object pointed to by X
OBJ_MOVE:
		ldd	xvel,x		;add velocity to position
		addd	xpos,x
		std	xpos,x
		ldd	yvel,x
		addd	ypos,x
		std	ypos,x
		rts

;;; handle bounds checking and wraparound of object pointed to by X
OBJ_BOUNDSCHK:	ldd	#0xFFBF		;max coordinates
		suba	siz,x
		subb	siz,x
		std	*TEMP1
;		tst	siz,x
;		beq	yboundscheck	;ignore the x check if size is 0
;
;xboundscheck:	lda	xpos_int,x
;		cmpa	#0xF8		;object has gone past left edge?
;		bhs	warptoright
;		cmpa	*TEMP1		;object has gone past right edge?
;		bls	yboundscheck
;
;warptoleft:	ldd	#0
;		std	xpos,x
;		bra	yboundscheck
;
;warptoright:	lda	*TEMP1
;		deca
;		clrb
;		std	xpos,x

yboundscheck:	lda	ypos_int,x
		cmpa	#0xF8		;object has gone past top edge?
		bhs	warptobottom
		cmpa	*TEMP2		;object has gone past bottom edge?
		bls	bchkdone

warptotop:	ldd	#0
		std	ypos,x
		bra	bchkdone

warptobottom:	lda	*TEMP2
		deca
		clrb
		std	ypos,x
bchkdone:	rts

;;; decrement the life of the object pointed to by X, if its life value
;;; is between 0x01 and 0x7F.
OBJ_UPDATELIFE:	tst	life,x
		beq	infinitelife	;0 life? already dead, skip
		bmi	infinitelife	;negative life? invincible
		dec	life,x
		ldb	pattern,x	;update explosion animation?
		cmpb	#SPR_EXPL1_START
		blo	noanim
		lda	life,x
		bita	#0b00000011
		bne	noanim
		addb	#4
		stb	pattern,x
noanim:
infinitelife:	rts

;;; for the 16-bit value v pointed to by X,
;;; compute 0.984375*v and store it back
;;; (done by subtracting v/64 from v.)
DECELERATE:	ldd	,x
		asra
		rorb
		asra
		rorb
		asra
		rorb
		asra
		rorb
		asra
		rorb
		asra
		rorb
		std	*TEMP1
		ldd	,x
		subd	*TEMP1
		std	,x
		rts

;------------------------------------------------------------------------------
; vertical blanking interrupt handler
;------------------------------------------------------------------------------
VBLANK:		lda	VDP_REG		;read status, clear interrupt flag
		
; send new sprite attributes
		ldd	#(VRAM|SPRATTABLE)
		stb	VDP_REG
		sta	VDP_REG

		lda	*FRAMECOUNTER
		bita	#1
		bne	drawbackwards

drawsprites:	ldx	#OBJECTS	
spriteloop:	tst	life,x		;skip dead objects
		beq	nextsprite
		lda	ypos_int,x	;y position
		sta	VDP_VRAM
		lda	xpos_int,x	;x position
		sta	VDP_VRAM
		lda	pattern,x	;sprite name
		sta	VDP_VRAM
		lda	#0x0F		;color
		sta	VDP_VRAM
nextsprite:	leax	OBJ_SIZE,x	;advance to next
		cmpx	#OBJECTS_END
		bne	spriteloop
		lda	#0xD0		;store end-of-sprite-list marker
		sta	VDP_VRAM
		bra	printscore

; on odd frames, reverse the sprite priorities to reduce fifth-sprite clipping
drawbackwards:	ldx	#OBJECTS_END-OBJ_SIZE
bspriteloop:	tst	life,x		;skip dead objects
		beq	bnextsprite
		lda	ypos_int,x	;y position
		sta	VDP_VRAM
		lda	xpos_int,x	;x position
		sta	VDP_VRAM
		lda	pattern,x	;sprite name
		sta	VDP_VRAM
		lda	#0x0F		;color
		sta	VDP_VRAM
bnextsprite:	leax	-OBJ_SIZE,x	;advance to next
		cmpx	#OBJECTS
		bhs	bspriteloop
		lda	#0xD0		;store end-of-sprite-list marker
		sta	VDP_VRAM


; print score
printscore:	ldx	#TEMP1		;convert BCD to ASCII
		lda	*SCORE
		jsr	BCD_TO_ASCII
		std	,x
		lda	*SCORE+1
		jsr	BCD_TO_ASCII
		std	2,x
		ldb	#3		;blank leading zeros
		lda	#'0		;zero character for comparison
lzerocheck:	cmpa	,x+		;is digit zero?
		bne	notzero		;no, done
		clr	-1,x		;yes, replace with blank
		decb
		bne	lzerocheck
notzero:	ldd	#(VRAM|NAMETABLE+32+1)	;print score
		stb	VDP_REG
		sta	VDP_REG
		lda	#4
		ldx	#TEMP1
digitloop:	ldb	,x+		;get character
printdigit:	stb	VDP_VRAM
		deca
		bne	digitloop
		ldb	#'0		;print final zero
		stb	VDP_VRAM

; print lives
printlives:	ldd	#(VRAM|NAMETABLE+64)	;print lives
		stb	VDP_REG
		sta	VDP_REG
		lda	#6		;max number of lives to print
printlifeloop:	ldb	#'^		;life character
		cmpa	*LIVES		;print life character or blank?
		bls	printlifechar
		clrb
printlifechar:	stb	VDP_VRAM
		deca
		bne	printlifeloop

; execute display action if necessary
		lda	*DISPLAY_ACTION
		beq	actiondone	;0? no action
		deca
		beq	aprinterror	;error action has highest priority
		deca
		beq	aprintstart
		deca
		beq	aprintgameover
		deca
		beq	aclearstrings
actiondone:	clr	*DISPLAY_ACTION
		
		jsr	READ_3BUTTON	;read controllers
		std	*PAD1STATE	;save controller 1 and 2 states
		rti


aprinterror:	ldd	#NAMETABLE
		ldx	*ERROR_MSG_PTR
		jsr	VDP_PRINTSTR
		bra	actiondone

aprintstart:	ldx	#startstr
		jsr	VDP_PRINTPSTR
		bra	actiondone

aprintgameover:	ldx	#gameoverstr	;print both strings
		jsr	VDP_PRINTPSTR
		jsr	VDP_PRINTPSTR
		bra	actiondone

aclearstrings:	ldx	#clrgameoverstr	;clear both strings
		jsr	VDP_PRINTPSTR
		jsr	VDP_PRINTPSTR
		bra	actiondone
	

;------------------------------------------------------------------------------
; subroutines
;------------------------------------------------------------------------------

;;; convert the packed BCD number in A to two ASCII characters in A and B
;;; arguments:	BCD number in A
;;; returns:	ASCII characters in A and B
;;; destroys:	none
BCD_TO_ASCII::	tfr	a,b
		andb	#0b00001111
		lsra
		lsra
		lsra
		lsra
		addd	#0x3030
		rts

;;; start a new game
;;; arguments:	none
;;; returns:	none
;;; destroys:	A,B,X
NEW_GAME::	jsr	CLR_OBJECTS
		ldb	#3
		stb	*START_ASTEROIDS ;first level will have 4 asteroids
		stb	*NEXT_LG_SAUCERS ;and 3 large saucers
		stb	*LIVES		;3 lives
		ldd	#0
		std	*SCORE
		std	*PAD1STATE
		std	*PREVPAD1STATE
		ldb	#EXTRA_LIFE_AMT
		stb	*NEXT_LIFE_AT
		sta	*BGSOUND_BITS	;clear sounds
		sta	*ATTRACTMODE	;clear attract mode
		sta	*HYPERSPACE	;clear hyperspace
		lda	#0x30		;start first level after a delay
		sta	*RESPAWN_TIMER
		sta	*NEW_LEVEL_TIMER
		lda	#clearstrings	;clear title screen strings
		sta	*DISPLAY_ACTION
		rts

;;; clear the entire asteroids array, marking all asteroids as dead
;;; arguments:	none
;;; returns:	none
;;; destroys:	X
CLR_ASTEROIDS::	ldx	#ASTEROIDS
		stx	*NEXT_AST_PTR	;initialize next asteroid pointer
clrloop:	clr	life,x
		leax	OBJ_SIZE,x
		cmpx	#ASTEROIDS_END
		bne	clrloop
		rts

;;; clears the entire objects array, marking all objects as dead
;;; arguments:	none
;;; returns:	none
;;; destroys:	X
CLR_OBJECTS:	ldx	#OBJECTS
		bra	clrloop

;;; vend a new asteroid and advance next asteroid pointer
;;; arguments:	none
;;; returns:	asteroid pointer in X
;;;		halts if no free asteroids
;;; destroys:	U
AST_NEW::	ldx	*NEXT_AST_PTR
		cmpx	#ASTEROIDS_END
		beq	no_asteroids
		leau	OBJ_SIZE,x
		stu	*NEXT_AST_PTR
		rts
; nothing we can do, halt
no_asteroids:	lda	#printerror
		sta	*DISPLAY_ACTION
		ldx	#objerror
		stx	*ERROR_MSG_PTR
		bra	.

;;; create a new set of asteroids (i.e. for level start)
;;; arguments:	number of asteroids in B
;;; returns:	
;;; destroys:	X,U
AST_NEW_SET::	jsr	CLR_ASTEROIDS
		ldx	#ASTEROIDS
		pshs	b
		lda	#7		;compute total number of asteroids
		mul			;B + 2*B + 4*B = 7*B 
		stb	*ASTEROIDS_LEFT
		ldb	,s
1$:		bsr	AST_NEW
		bsr	AST_INIT
		leax	OBJ_SIZE,x
		dec	,s
		bne	1$
		puls	b,pc

;;; split a large asteroid into two smaller asteroids, or remove it
;;; if it is a small asteroid
;;; arguments:	pointer to asteroid in X
;;; returns:	none
;;; destroys:	A,B,Y,U,TEMP1,TEMP2,TEMP3,TEMP4
AST_SPLIT::	pshs	x
		lda	siz,x		;compute center point of asteroid
		asra			;(offset by half of size)
		tfr	a,b
		adda	xpos,x
		addb	ypos,x
		std	*TEMP1		;save center point
		lda	siz,x		;what's the new size?
		cmpa	#AST_LG_SIZE	;large?
		beq	split_med	;split into two medium asteroids
		cmpa	#AST_MED_SIZE	;medium?
		beq	split_sm	;split into two small asteroids
		puls	x,pc		;small? return
split_med:	ldd	#(SPR_AST1_MED<<8)|AST_MED_SIZE
		std	*TEMP3
		bra	do_split
split_sm:	ldd	#(SPR_AST1_SM<<8)|AST_SM_SIZE
		std	*TEMP3
; spawn two new asteroids
do_split:	lda	#2
		ldb	*TEMP4		;get new size offset (divide in half)
		asrb
		pshs	d
1$:		bsr	AST_NEW		;get a new asteroid
		ldd	*TEMP3		;set new pattern and size
		std	pattern,x
		lda	*TEMP1		;set x position
		suba	1,s
		clrb
		std	xpos,x		;set y position
		lda	*TEMP2
		suba	1,s
		clrb
		std	ypos,x
		ldd	#0xFF00|asteroid
		std	life,x
		bsr	ast_randomize	;randomize velocity and pattern
		dec	,s
		bne	1$
		puls	a,b,x,pc

;;; generates a new large asteroid, positions it on one of the 4 screen edges,
;;; and gives it a random direction
;;; arguments:	asteroid pointer in X
;;; returns:	asteroid structure initialized
;;; destroys:	A,B,U
AST_INIT::	ldd	#0xFF00|asteroid	;mark as alive
		std	life,x
		jsr	RANDBYTE	;get a random byte
		andb	#0b00111110	;convert to position table offset
		ldu	#AST_POSITIONS
		ldd	b,u		;read x and y positions
		sta	xpos_int,x	;store x position
		clr	xpos_frac,x
		stb	ypos_int,x	;store y position
		clr	ypos_frac,x
		ldd	#(SPR_AST1_LG<<8)|AST_LG_SIZE	;set pattern and size
		std	pattern,x

ast_randomize:	jsr	RANDBYTE	;get a random byte
		pshs	b		;save it
		andb	#0b01111100	;convert to direction table offset
		ldu	#AST_DIRECTIONS
		leau	b,u		;advance to table entry
		ldd	,u++		;get x direction
		std	xvel,x
		ldd	,u		;get y direction
		std	yvel,x
		puls	b		;get the random number back
		andb	#0b00000011	;asteroid shape: 0 to 3
		lslb			;multiply by 4 to get sprite number
		lslb
		addb	pattern,x	;add to existing pattern number
		stb	pattern,x
		rts

;;; initialize the player ship
;;; positions it in the center, facing right
;;; arguments:	none
;;; returns:	ship structure and variables initialized
;;; destroys:	A,B,X
SHIP_INIT::	ldx	#PLAYERSHIP
		ldd	#0xFF00|player1
		std	life,x
		lda	*HYPERSPACE	;are we hyperspacing?
		beq	spawn_center	;no, spawn in the center
		cmpa	#0b11111000	;will hyperspace kill?
		lbeq	ship_kill
spawn_random:	jsr	RANDBYTE	;get random x position
		cmpb	#255-SHIP_SIZE	;clamp to screen
		blo	set_rand_x
		ldb	#255-SHIP_SIZE
set_rand_x:	stb	xpos,x
		clr	xpos_frac,x
		jsr	RANDBYTE	;get random y position
		cmpb	#191-SHIP_SIZE	;clamp to screen
		blo	set_rand_y
		ldb	#191-SHIP_SIZE
set_rand_y:	stb	ypos,x
		clr	ypos_frac,x
		bra	zero_vel
spawn_center:	ldd	#0x7800		;center x
		std	xpos,x
		ldd	#0x5800		;center y
		std	ypos,x
zero_vel:	ldd	#0		;zero velocity
		std	xvel,x
		std	yvel,x
		tst	*HYPERSPACE	;don't set pattern/size if hyperspacing
		bne	ship_init_done
		ldd	#(SPR_SHIP<<8)|16
		std	pattern,x	;pattern and size
		clr	*SHIPANGLE
ship_init_done:	rts

;;; initializes a saucer
;;; arguments:	none
;;; returns:	none
;;; destroys:	A,B,X,U
SAUCER_INIT:	ldx	#SAUCER
		ldd	#0xFF00|saucer
		std	life,x
		ldd	#0
		std	yvel,x		;zero y velocity initially
		std	xpos,x		;start on left
		tst	*LARGE_SAUCERS	;spawn a large saucer?
		beq	smallsaucer	;out of large saucers, make it small
largesaucer:	dec	*LARGE_SAUCERS
		ldd	#0x00A0		;slow speed, moving right
		std	xvel,x
		ldd	#(SPR_SAUCER_LG<<8)|SAUCER_LG_SIZE
		std	pattern,x
		ldu	#LARGESAUCER	;set up sound effect
		stu	*SAUCERSNDPTR
		bra	positionsaucer
smallsaucer:	ldd	#0x00D0		;fast speed, moving right
		std	xvel,x
		ldd	#(SPR_SAUCER_SM<<8)|SAUCER_SM_SIZE
		std	pattern,x
		ldu	#SMALLSAUCER	;set up sound effect
		stu	*SAUCERSNDPTR
positionsaucer:	jsr	RANDBYTE	;get a random byte
		tfr	b,a		;save it
		lslb			;vertical position: reduce to 0-127
		addb	#30		;roughly center the range onscreen
		stb	ypos_int,x	;set y position
		clr	ypos_frac,x
		tsta			;swap to right side?
		bpl	saucerdone	;if random byte msb clear, keep on left
		neg	xvel+1,x	;right side: negate x velocity
		com	xvel,x
		com	xpos,x		;and move to right edge
saucerdone:	jsr	SAUCERSND_ON	;play sound
		rts

;;; make the saucer switch directions or fire if appropriate
SAUCER_ACTION:	lda	*FRAMECOUNTER
		bita	#0b00111111
		beq	saucerfire	;fire every 64 frames
saucerchkmove:	lda	*FRAMECOUNTER
		bita	#0b01111111
		beq	saucermove	;move every 128 frames
sauceractdone:	rts

saucermove:	jsr	RANDBYTE	;get a random byte
		andb	#0b00000110	;set one of four y velocities
		ldu	#saucer_yvels	;with a table lookup
		ldd	b,u
		std	SAUCER+yvel
		bra	sauceractdone

saucerfire:	jsr	GET_SCRBULLET	;get a bullet
		beq	saucerchkmove	;bail if none available
		jsr	RANDBYTE	;get a random byte for direction
		andb	#0b00011111
		ldy	#SAUCER
		jsr	FIRE_BULLET	;fire the bullet
		ldd	#SAUCERFIRE	;play sound
		std	*SNDPTR
		bra	saucerchkmove	

;;; set up the next saucer spawn
;;; arguments:	none
;;; returns:	none
;;; destroys:	A,B
SAUCER_NEXT:	tst	*ATTRACTMODE	;don't respawn saucers in attract mode
		bne	nonextsaucer
		lda	*NEXT_SAUCER_INT ;decrement time to next saucer?
		cmpa	#90		;not if it's at the minimum of 3 secs
		bls	resetstimer
		suba	#15		;shorten by half a second
		sta	*NEXT_SAUCER_INT
resetstimer:	sta	*SAUCER_TIMER	;reload saucer timer
nonextsaucer:	rts

;;; checks if if is safe for the ship to spawn
;;; (i.e. there are no asteroids near the center of the screen)
;;; arguments:	none
;;; returns:	Z flag set if it is safe, Z flag clear otherwise
;;; destroys:	A,X
SHIP_CAN_SPAWN:	tst	*HYPERSPACE	;are we hyperspacing?
		bne	canspawn	;if yes, skip the check
		ldx	#ASTEROIDS
scs_astloop:	tst	life,x
		bpl	scs_nextast
		lda	xpos,x
		cmpa	#0x50		;check min x
		blo	scs_nextast
		cmpa	#0xA0		;check max x
		bhi	scs_nextast
		lda	ypos,x		;check min y
		cmpa	#0x30
		blo	scs_nextast
		cmpa	#0x80
		bhi	scs_nextast
		andcc	#0b11111011	;can't spawn, clear Z
		rts
scs_nextast:	leax	OBJ_SIZE,x	;asteroid is clear, check next
		cmpx	#ASTEROIDS_END
		bne	scs_astloop
canspawn:	orcc	#0b00000100	;can spawn, set Z
		rts

;;; initialize the bullets
;;; just sets them all to be dead
BULLETS_INIT::	ldx	#BULLETS
1$:		clr	life,x
		leax	OBJ_SIZE,x
		cmpx	#BULLETS_END
		bne	1$
		rts

;;; finds an available bullet
;;; returns a pointer to it in X or sets Z if no bullets available
GET_BULLET::	ldx	#SHIPBULLETS
1$:		tst	life,x
		beq	foundbullet
		leax	OBJ_SIZE,x
		cmpx	#SHIPBULLETS_END
		bne	1$
nobullet:	clra			;set Z flag, no bullets available
		rts
foundbullet:	andcc	#0b11111011	;clear Z flag
		rts

;;; finds an available bullet for the saucer
;;; returns a pointer to it in X or sets Z if no bullets available
GET_SCRBULLET::	ldx	#SAUCERBULLETS
1$:		tst	life,x
		beq	foundbullet
		leax	OBJ_SIZE,x
		cmpx	#SCRBULLETS_END
		bne	1$
		bra	nobullet

;;; fires a bullet
;;; arguments:	pointer to bullet in X
;;; 		pointer to object firing bullet in Y
;;;		bullet angle in B
;;; returns:	none
;;; destroys:	A,B,U
FIRE_BULLET::	ldu	#TRIGTABLE	;get bullet velocity vector
		lslb
		lslb
		leau	b,u		;get entry in trig table
		ldd	,u++		;get cosine value
		lslb
		rola
		std	xvel,x		;set x velocity
		ldd	,u		;get sine value
		lslb
		rola
		std	yvel,x		;set y velocity

		ldd	xpos,y
		addd	xvel,x
		addd	#0x0600
		std	xpos,x

		ldd	ypos,y		;set y position
		addd	yvel,x
		addd	#0x0600
		std	ypos,x

		ldd	#(SPR_BULLET<<8)|0	;set bullet pattern and size
		std	pattern,x
		ldd	#0x5000|bullet	;set type and owner
		orb	type,y
		std	life,x
		rts

;;; bullet/object collision detection
;;; arguments:	pointer to object in X
;;;		pointer to bullet in Y
;;; returns:	none
;;; destroys:	A
BULLET_COLL::	tst	life,x		;skip dead objects
		bpl	nocoll

		lda	xpos,x		;check min x position
		cmpa	xpos,y
		bhi	nocoll

		lda	ypos,x		;check min y position
		cmpa	ypos,y
		bhi	nocoll

		lda	xpos,x		;check max x position
		adda	siz,x
		cmpa	xpos,y
		blo	nocoll

		lda	ypos,x
		adda	siz,x
		cmpa	ypos,y
		blo	nocoll

; collision: kill the bullet and object
		clr	life,y
		jsr	OBJ_SCORE
		bra	OBJ_KILL		
; no collision, return
nocoll:		rts

;;; object/object collision detection
;;; arguments:	for ship/asteroid:
;;;		  asteroid pointer in X, ship pointer in Y
;;;		for saucer/asteroid:
;;;		  asteroid pointer in X, saucer pointer in Y
;;;		for ship/saucer:
;;;		  saucer pointer in X, ship pointer in Y
;;; returns:	none
;;; destroys:	A,B,Y
OBJ_OBJ_COLL::	lda	siz,y		;compute center point of object
		asra			;(offset by half of size)
		tfr	a,b
		adda	xpos,y
		addb	ypos,y
		std	*TEMP1		;save center point
		
		lda	xpos,x		;check min x position
		suba	#3
		cmpa	*TEMP1
		bhi	ao_nocoll
		
		lda	ypos,x		;check min y position
		suba	#3
		cmpa	*TEMP2
		bhi	ao_nocoll
		
		lda	xpos,x		;check max x position
		adda	siz,x
		adda	#3
		cmpa	*TEMP1
		blo	ao_nocoll
		
		lda	ypos,x		;check max y position
		adda	siz,x
		adda	#3
		cmpa	*TEMP2
		blo	ao_nocoll
; collision: kill both objects
		bsr	OBJ_SCORE
		bsr	OBJ_KILL
		tfr	y,x
		bsr	OBJ_KILL
; no collision: return
ao_nocoll:	rts	

;;; kill an object, replace it with an explosion animation
;;; arguments:	pointer to object in X
;;; returns:	none
;;; destroys:	A,B
OBJ_KILL::	ldd	#0
		std	xvel,x		;set velocity to 0
		std	yvel,x
		lda	#EXPLOSION_SIZE	;make sure explosion is centered
		suba	siz,x		;(offset by half of size difference)
		asra
		clrb
		std	*TEMP1
		ldd	xpos,x
		subd	*TEMP1
		std	xpos,x
		ldd	ypos,x
		subd	*TEMP1
		std	ypos,x
		lda	type,x		;is it a player ship?
		bita	#player_mask
		bne	ship_kill
		cmpa	#saucer		;is it a saucer?
		beq	saucer_kill
		cmpa	#asteroid	;is it an asteroid?
		bne	obj_kill	;no, something else
		jsr	AST_SPLIT	;if it's an asteroid, split it
		dec	*ASTEROIDS_LEFT	;and decrement asteroid count
		beq	nextlevel	;last one destroyed? new level!

obj_kill:	lda	#SPR_EXPL1_START
		sta	pattern,x
		lda	#0x10		;set countdown timer
		sta	life,x
		ldb	siz,x
		jsr	SND_EXPLODE
		rts
saucer_kill:	jsr	SAUCERSND_OFF	;stop sound
		jsr	SAUCER_NEXT	;set up the next one
		bra	obj_kill

ship_kill:	lda	#SPR_EXPL2_START
		sta	pattern,x
		clr	*HYPERSPACE
		clr	*SAUCER_TIMER	;clear saucer timer until respawn
		lda	#0x30
		sta	life,x
		jsr	THUMPSND_OFF	;turn off thump sound
		ldb	#16		;explosion sound
		jsr	SND_EXPLODE
		dec	*LIVES		;lose a life
		beq	do_gameover	;last life lost? it's game over man
		lda	#0x60
		sta	*RESPAWN_TIMER	;set respawn timer
		rts

nextlevel:	lda	#0x60
		sta	*NEW_LEVEL_TIMER
		clr	*SAUCER_TIMER
		jsr	THUMPSND_OFF	;turn off thump sound
		bra	obj_kill

;;; add points for a killed object to score
;;; arguments:	pointer to killed object in X
;;;		pointer to bullet/object that did the killing in Y
;;; returns:	none
;;; destroys:	A,B
OBJ_SCORE::	lda	type,y		;who killed the object?
		bita	#player_mask	;was it a player?
		beq	noscore		;if not, no score
		lda	siz,x
		clc
; points determined by size, it's a hack i know
		cmpa	#AST_LG_SIZE
		beq	score_lg
		cmpa	#SAUCER_LG_SIZE
		beq	score_lgsaucer
		cmpa	#AST_MED_SIZE
		beq	score_med
		cmpa	#SAUCER_SM_SIZE
		beq	score_smsaucer
		cmpa	#AST_SM_SIZE
		beq	score_sm
noscore:	rts
; add to score
score_lgsaucer:	lda	#0x20
		bra	addscore
score_smsaucer:	lda	#0x99		;1000 points (990+carry)
		sec
		bra	addscore
score_lg:	lda	#0x02
		bra	addscore
score_med:	lda	#0x05
		bra	addscore
score_sm:	lda	#0x10
addscore:	adca	*SCORE+1
		daa
		sta	*SCORE+1
		lda	#0
		adca	*SCORE
		daa
		sta	*SCORE
; check for extra life
; A should contain score MSB
chkextralife:	cmpa	*NEXT_LIFE_AT	;score >= extra life score?
		blo	noextralife	;no, return
		ldb	*LIVES		;less than 255 lives?
		cmpb	#0xFF
		beq	noextralife	;no, return to prevent overflow
		inc	*LIVES		;add life
		lda	#EXTRA_LIFE_AMT	;advance amount for next life
		adda	*NEXT_LIFE_AT
		daa
		sta	*NEXT_LIFE_AT
		jsr	LIFESND_ON	;play extra life sound
noextralife:	rts

do_gameover:	lda	#printgameover
		sta	*DISPLAY_ACTION
		sta	*ATTRACTMODE	;reenable attract mode
		rts

;;; set sprite attributes
;;; arguments:	pointer to 4-byte sprite attribute structure in X
;;;		sprite number (0-31) in B
;;; returns:	none
;;; destroys:	A,B,X
SETSPRITE::	clra			;compute sprite attr. table offset
		lslb			;multiply sprite number by 4
		lslb
		addd	#(VRAM|SPRATTABLE)	;add base address
		stb	VDP_REG		;send VRAM address
		sta	VDP_REG
		lda	,x+		;copy unrolled 4 times
		sta	VDP_VRAM
		lda	,x+
		sta	VDP_VRAM
		lda	,x+
		sta	VDP_VRAM
		lda	,x+
		sta	VDP_VRAM
		rts

;;; set the number of sprites to display
;;; writes a value of 0xD0 into the Y coordinate of the last sprite
;;; arguments:	number of sprites in B (0-32)
;;; returns:	none
;;; destroys:	A,B
SETNUMSPRITES::	cmpb	#32		;for values >= 32, do nothing
		bhs	maxsprites
		clra			;otherwise, compute table offset
		lslb			;multiply sprite number by 4
		lslb
		addd	#(VRAM|SPRATTABLE)	;add base address
		stb	VDP_REG		;send VRAM address
		sta	VDP_REG
		lda	#0xD0		;store end marker
		sta	VDP_VRAM
maxsprites:	rts


SND_UPDATE::	tst	*SNDPTR		;null pointer? if so, skip
		beq	update_bgsnd
		ldx	*SNDPTR		;otherwise, advance sound pointer
		ldd	,x++		;read 16-bit value
		beq	mute		;is it 0x0000? if so, mute
		bmi	repeat		;is it negative? if so, repeat
		stx	*SNDPTR		;otherwise, store advanced pointer
		jsr	PSG_SET_AFREQ	;and play the sound
		ldd	#(PSG_A_AMPL<<8)|15
		std	PSG
		bra	update_bgsnd
mute:		clr	*SNDPTR
		ldd	#(PSG_A_AMPL<<8)|0
		std	PSG
		bra	update_bgsnd
repeat:		leax	d,x		;back up the pointer
		stx	*SNDPTR

update_bgsnd:	lda	*BGSOUND_BITS
		bita	#lifesnd
		bne	playlifesnd
		bita	#saucersnd
		bne	playsaucersnd
		bita	#thrustsnd
		bne	playthrustsnd
		bita	#thumpsnd
		bne	playthumpsnd
nobgsnd:	ldd	#(PSG_B_AMPL<<8)|0	;no background sounds?
		std	PSG			;silence channel
		rts

playlifesnd:	lda	*LIFESND_TIMER	;play 3 kHz or silence?
		bita	#0b00000100
		bne	play3khz	;bit 2 set? play 3 kHz
		ldd	#(PSG_B_AMPL<<8)|0	;otherwise, silence
declifesnd:	std	PSG
		dec	*LIFESND_TIMER
		beq	LIFESND_OFF	;halt timer at 0
		rts

play3khz:	ldd	#41		;3 kHz tone
		jsr	PSG_SET_BFREQ
		ldd	#(PSG_B_AMPL<<8)|15
		bra	declifesnd

playsaucersnd:	ldx	*SAUCERSNDPTR	;advance saucer sound pointer
playsaucersnd2:	ldd	,x++		;read 16-bit value
		bmi	saucersndrept	;is it negative? if so, repeat
		stx	*SAUCERSNDPTR	;otherwise, store advanced pointer
		jsr	PSG_SET_BFREQ	;and play the sound
		ldd	#(PSG_B_AMPL<<8)|15
		std	PSG
		rts

saucersndrept:	leax	d,x		;back up the pointer
		bra	playsaucersnd2	;play new sample

playthrustsnd:	ldd	#2048
		jsr	PSG_SET_BFREQ
		ldd	#(PSG_B_AMPL<<8)|15
		std	PSG
		rts

playthumpsnd:	lda	*THUMP_TIMER
		cmpa	#4		;thump sound lasts for 4 frames
		bhi	nobgsnd		;otherwise, silence channel
		ldd	#1344
		tst	*THUMP_PITCH	;high or low pitch?
		bne	setthumpfreq
		addd	#88
setthumpfreq:	jsr	PSG_SET_BFREQ
		ldd	#(PSG_B_AMPL<<8)|15
		std	PSG
		rts

THRUSTSND_ON::	lda	*BGSOUND_BITS
		ora	#thrustsnd
		sta	*BGSOUND_BITS
		rts

THRUSTSND_OFF::	lda	*BGSOUND_BITS
		anda	#~thrustsnd
		sta	*BGSOUND_BITS
		rts

THUMPSND_ON::	lda	*BGSOUND_BITS
		bita	#thumpsnd	;don't reset thump if it's already on
		bne	thumpalreadyon
		ora	#thumpsnd
		sta	*BGSOUND_BITS
		clr	*THUMP_PITCH
		lda	#4
		sta	*THUMP_TIMER
thumpalreadyon:	rts

THUMPSND_OFF::	lda	*BGSOUND_BITS
		anda	#~thumpsnd
		sta	*BGSOUND_BITS
		rts

LIFESND_ON::	lda	*BGSOUND_BITS
		ora	#lifesnd
		sta	*BGSOUND_BITS
		lda	#88
		sta	*LIFESND_TIMER
		rts

LIFESND_OFF::	lda	*BGSOUND_BITS
		anda	#~lifesnd
		sta	*BGSOUND_BITS
		rts

SAUCERSND_ON::	lda	*BGSOUND_BITS
		ora	#saucersnd
		sta	*BGSOUND_BITS
		rts

SAUCERSND_OFF::	lda	*BGSOUND_BITS
		anda	#~saucersnd
		sta	*BGSOUND_BITS
		rts

SND_EXPLODE::	decb			;convert size to frequency
		lslb
		lda	#PSG_NOISE_FREQ
		std	PSG
		ldd	#(PSG_ENV_SHAPE<<8)|0
		std	PSG
		rts

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
		.fcb	0x82	;Graphics I, 16K, display off, 16x16 sprites
		.fcb	NAMETABLE/0x0400
		.fcb	COLORTABLE/0x0040
		.fcb	PATTABLE/0x0800
		.fcb	SPRATTABLE/0x0080
		.fcb	SPRPATTABLE/0x0800
		.fcb	0x01	;black background

; positioned strings, prefixed with VRAM addresses (screen positions)
authorstr:	.fdb	NAMETABLE+10+(32*22)
		.fcb	'",'#,'$,'%,'&,'','(,'),'*,'+,',,'-,0

gameoverstr:	.fdb	NAMETABLE+11+(32*6)
		.asciz	"GAME OVER"

startstr:	.fdb	NAMETABLE+11+(32*18)
		.asciz	"PUSH START"

clrgameoverstr:	.fdb	NAMETABLE+11+(32*6)
		.asciz	"         "

clrstartstr:	.fdb	NAMETABLE+11+(32*18)
		.asciz	"          "

; plain strings
objerror:	.asciz	"OUT OF OBJECTS"

; saucer data
saucer_yvels:	.fdb	0x0000,0xFF60,0x00A0,0x0000

; patterns
SPRITEPATS:
	.include "sprites.inc"
SPRITEPATS_END	.equ	.

TEXTPATS:
	.include "text.inc"
TEXTPATS_END	.equ	.

; sprite pattern numbers
SPR_AST1_LG	.equ	0
SPR_AST2_LG	.equ	4
SPR_AST3_LG	.equ	8
SPR_AST4_LG	.equ	12
SPR_AST1_MED	.equ	16
SPR_AST2_MED	.equ	20
SPR_AST3_MED	.equ	24
SPR_AST4_MED	.equ	28
SPR_AST1_SM	.equ	32
SPR_AST2_SM	.equ	36
SPR_AST3_SM	.equ	40
SPR_AST4_SM	.equ	44
SPR_SAUCER_LG	.equ	48
SPR_SAUCER_SM	.equ	52
SPR_BULLET	.equ	56
SPR_SHIP	.equ	64
SPR_EXPL1_START	.equ	192	;asteroid/saucer explosion
SPR_EXPL2_START	.equ	208	;ship explosion

; trig tables
; 32 entries each, 8.8 signed fixed point (2 bytes/entry, 64 bytes/table)
	.include "trig.inc"
	.include "directions.inc"
	.include "positions.inc"

; sound effect frequencies
	.include "sounds.inc"

;------------------------------------------------------------------------------
; data structures
;------------------------------------------------------------------------------

; objects
OBJECTS		.equ	.
BULLETS		.equ	.
SHIPBULLETS:	.rmb	OBJ_SIZE*NUM_SHIPBULLETS
SHIPBULLETS_END	.equ	.
SAUCERBULLETS:	.rmb	OBJ_SIZE*NUM_SCRBULLETS
SCRBULLETS_END	.equ	.
BULLETS_END	.equ	.

PLAYERSHIP:	.rmb	OBJ_SIZE
SAUCER:		.rmb	OBJ_SIZE
SHIPS_END	.equ	.

; Asteroids array.
; Since we have enough memory, asteroid slots are not reused.
; New asteroids are spawned at the end of the list, we don't
; bother to reclaim old slots.
ASTEROIDS:	.rmb	(OBJ_SIZE*NUM_ASTEROIDS)
ASTEROIDS_END	.equ	.

OBJECTS_END	.equ	.


