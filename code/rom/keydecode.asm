; vim:noet:sw=8:ts=8:ai:syn=as6809
; Matt Sarnoff (msarnoff.org/6809) - January 26, 2011
;
;************ PS/2 keyboard scancode decoding ************

	.include "keycodes.inc"

;;; convert a scancode to an ASCII value or special key symbol
;;; arguments:	modifier state in A
;;;		scancode in B
;;; returns:	new modifier state in A
;;;		ASCII value (or special key symbol) in B
;;; destroys:	none
;;;
;;; The modifier state byte consists of the following bits:
;;; bit 0: set if previous scancode was 0xE0 or 0xE1 (used internally)
;;; bit 1: set if previous scancode was 0xF0 (used internally)
;;; bit 6: set if Control is depressed
;;; bit 7: set if Shift is depressed
KBD_DECODE::	cmpb	#0xF0
		beq	keyup		;set the key up bit
		cmpb	#0xE0
		bhs	extended	;set the extended bit (E0 and E1)
; not a special keycode
		bita	#KEY_UP_BIT
		beq	keypress	;if up bit is clear, this is a keypress
		bra	keyrelease	;otherwise, it's a release

keyup:		ora	#KEY_UP_BIT
		clrb
		rts
extended:	ora	#EXTENDED_BIT
		clrb
		rts

; handling a key release
keyrelease:	anda	#~KEY_UP_BIT
		cmpb	#0x12		;is it a modifier key?
		beq	lshiftrelease
		cmpb	#0x59
		beq	rshiftrelease
		cmpb	#0x14
		beq	ctrlrelease
		cmpb	#0x11
		beq	altrelease
		bra	moddone
lshiftrelease:	anda	#~L_SHIFT_BIT
		bra	moddone
rshiftrelease:	anda	#~R_SHIFT_BIT
		bra	moddone
ctrlrelease:	bita	#EXTENDED_BIT
		bne	rctrlrelease	;if prefixed with E0, right ctrl
		anda	#~L_CTRL_BIT
		bra	moddone
rctrlrelease:	anda	#~R_CTRL_BIT
		bra	moddone
altrelease:	bita	#EXTENDED_BIT
		bne	raltrelease	;if prefixed with E0, right alt
		anda	#~L_ALT_BIT
		bra	moddone
raltrelease:	anda	#~R_ALT_BIT
		bra	moddone

; handling a key press
keypress:	cmpb	#0x12		;is it a modifier key?
		beq	lshiftpress
		cmpb	#0x59
		beq	rshiftpress
		cmpb	#0x14
		beq	ctrlpress
		cmpb	#0x11
		beq	altpress
		bra	otherpress
lshiftpress:	ora	#L_SHIFT_BIT
		bra	moddone
rshiftpress:	ora	#R_SHIFT_BIT
		bra	moddone
ctrlpress:	bita	#EXTENDED_BIT
		bne	rctrlpress	;if prefixed with E0, right ctrl
		ora	#L_CTRL_BIT
		bra	moddone
rctrlpress:	ora	#R_CTRL_BIT
		bra	moddone
altpress:	bita	#EXTENDED_BIT
		bne	raltpress	;if prefixed with E0, right alt
		ora	#L_ALT_BIT
		bra	moddone
raltpress:	ora	#R_ALT_BIT
moddone:	anda	#~(EXTENDED_BIT|KEY_UP_BIT)
		clrb
		rts

; other key pressed? convert to ASCII using tables
otherpress:	pshs	u
		ldu	#code_table	;which code table to use?
		bita	#EXTENDED_BIT
		bne	useextended	;extended bit set? use extended table
		bita	#(L_SHIFT_BIT|R_SHIFT_BIT)
		bne	useshift	;either shift bit set? use shift table
		bra	keylookup	;none? use regular table
useextended:	ldu	#extended_table
		subb	#0x48		;all extended codes are higher than 0x48
		andb	#0b00111111	;so i'm not wasting 72 bytes of zeros
		bra	keylookup
useshift:	ldu	#shift_table

keylookup:	cmpb	#0x83		;F7 is the weird key with a code > 0x7F
		bne	not_f7
		ldb	#K_F7
		bra	keypressdone
not_f7:		ldb	b,u		;get ASCII code from lookup table
		bita	#(L_CTRL_BIT|R_CTRL_BIT)
		bne	controlcode	;ctrl bit set? make a control code
keypressdone:	anda	#~EXTENDED_BIT
		tstb
		puls	u,pc

controlcode:	andb	#31		;mask off top bits
		bra	keypressdone

;************ Scancode tables (set 2) ************

; Normal (non-shifted) scancodes
code_table:
	.fcb	0,     K_F9,  0,     K_F5,  K_F3,  K_F1,  K_F2,  K_F12
	.fcb	0,     K_F10, K_F8,  K_F6,  K_F4,  9,     '`,    0
	.fcb	0,     0,     0,     0,     0,     'q,    '1,    0
	.fcb	0,     0,     'z,    's,    'a,    'w,    '2,    0
	.fcb	0,     'c,    'x,    'd,    'e,    '4,    '3,    0
	.fcb	0,     32,    'v,    'f,    't,    'r,    '5,    0
	.fcb	0,     'n,    'b,    'h,    'g,    'y,    '6,    0
	.fcb	0,     0,     'm,    'j,    'u,    '7,    '8,    0
	.fcb	0,     ',,    'k,    'i,    'o,    '0,    '9,    0
	.fcb	0,     '.,    '/,    'l,    ';,    'p,    '-,    0
	.fcb	0,     0,     '',    0,     '[,    '=,    0,     0
	.fcb	K_CPL, 0,     13,    '],    0,     '\,    0,     0
	.fcb	0,     0,     0,     0,     0,     0,     8,     0
	.fcb	0,     '1,    0,     '4,    '7,    0,     0,     0
	.fcb	'0,    '.,    '2,    '5,    '6,    '8,    K_ESC, K_NML
	.fcb	K_F11, '+,    '3,    '-,    '*,    '9,    K_SCL, 0

; Shifted scancodes
shift_table:
	.fcb	0,     K_F9,  0,     K_F5,  K_F3,  K_F1,  K_F2,  K_F12
	.fcb	0,     K_F10, K_F8,  K_F6,  K_F4,  9,     '~,    0
	.fcb	0,     0,     0,     0,     0,     'Q,    '!,    0
	.fcb	0,     0,     'Z,    'S,    'A,    'W,    '@,    0
	.fcb	0,     'C,    'X,    'D,    'E,    '$,    '#,    0
	.fcb	0,     32,    'V,    'F,    'T,    'R,    '%,    0
	.fcb	0,     'N,    'B,    'H,    'G,    'Y,    '^,    0
	.fcb	0,     0,     'M,    'J,    'U,    '&,    '*,    0
	.fcb	0,     '<,    'K,    'I,    'O,    '),    '(,    0
	.fcb	0,     '>,    '?,    'L,    ':,    'P,    '_,    0
	.fcb	0,     0,     '",    0,     '{,    '+,    0,     0
	.fcb	K_CPL, 0,     10,    '},    0,     '|,    0,     0
	.fcb	0,     0,     0,     0,     0,     0,     8,     0
	.fcb	0,     '1,    0,     '4,    '7,    0,     0,     0
	.fcb	'0,    '.,    '2,    '5,    '6,    '8,    K_ESC, K_NML
	.fcb	K_F11, '+,    '3,    '-,    '*,    '9,    K_SCL, 0
	
; Extended scancodes
extended_table:
	.fcb	0,     0,     '/,    0,     0,     0,     0,     0
	.fcb	0,     0,     0,     0,     0,     0,     0,     0
	.fcb	0,     0,     10,    0,     0,     0,     0,     0
	.fcb	0,     0,     0,     0,     0,     0,     0,     0
	.fcb	0,     K_END, 0,     K_LF,  K_HOM, 0,     0,     0
	.fcb	K_INS, K_DEL, K_DN,  '5,    K_RT,  K_UP,  0,     K_BRK
	.fcb	0,     0,     K_PGD, 0,     K_PRS, K_PGU, 0,     0

