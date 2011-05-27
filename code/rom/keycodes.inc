; vim:noet:sw=8:ts=8:ai:syn=as6809
; Matt Sarnoff (msarnoff.org/6809) - January 26, 2011
;
;************ PS/2 keyboard scancode decoding ************

;;; Modifier state bits
L_SHIFT_BIT	.equ	0b10000000
R_SHIFT_BIT	.equ	0b01000000
L_CTRL_BIT	.equ	0b00100000
R_CTRL_BIT	.equ	0b00010000
L_ALT_BIT	.equ	0b00001000
R_ALT_BIT	.equ	0b00000100
EXTENDED_BIT	.equ	0b00000010
KEY_UP_BIT	.equ	0b00000001

;;; Non-ASCII key codes
K_ESC	.equ	0x1B
K_CPL	.equ	0x80	;caps lock
K_F1	.equ	0x81
K_F2	.equ	0x82
K_F3	.equ	0x83
K_F4	.equ	0x84
K_F5	.equ	0x85
K_F6	.equ	0x86
K_F7	.equ	0x87
K_F8	.equ	0x88
K_F9	.equ	0x89
K_F10	.equ	0x8A
K_F11	.equ	0x8B
K_F12	.equ	0x8C
K_UP	.equ	0x8D	;up arrow
K_LF	.equ	0x8E	;left arrow
K_DN	.equ	0x8F	;down arrow
K_RT	.equ	0x90	;right arrow
K_INS	.equ	0x91	;insert
K_DEL	.equ	0x92	;delete
K_HOM	.equ	0x93	;home
K_END	.equ	0x94	;end
K_PGU	.equ	0x95	;page up
K_PGD	.equ	0x96	;page down
K_NML	.equ	0x97	;num lock
K_SCL	.equ	0x98	;scroll lock
K_PRS	.equ	0x99	;print screen
K_BRK	.equ	0x9A	;break

