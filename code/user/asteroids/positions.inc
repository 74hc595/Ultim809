; vim:noet:sw=8:ts=8:ai:syn=as6809
; Asteroid initial position table
; 32 possible initial positions around edge of screen

AST_POSITIONS:	.fcb	0,0	;top edge
		.fcb	24,0
		.fcb	48,0
		.fcb	72,0
		.fcb	96,0
		.fcb	120,0
		.fcb	144,0
		.fcb	168,0
		.fcb	192,0
		.fcb	216,0

		.fcb	0,25	;left edge
		.fcb	0,50
		.fcb	0,75
		.fcb	0,100
		.fcb	0,125
		.fcb	0,150

		.fcb	239,25	;right edge
		.fcb	239,50
		.fcb	239,75
		.fcb	239,100
		.fcb	239,125
		.fcb	239,150

		.fcb	0,175	;bottom edge
		.fcb	24,175
		.fcb	48,175
		.fcb	72,175
		.fcb	96,175
		.fcb	120,175
		.fcb	144,175
		.fcb	168,175
		.fcb	192,175
		.fcb	216,175

