; vim:noet:sw=8:ts=8:ai:syn=as6809
    
		lda	0xC418		;set controller select line
		lda	#PSG_IO_A	;read controller 1
		sta	PSG_LATCH_ADDR
		lda	PSG_READ_ADDR	;up, down, left, right, B, C
		sta	PAD1STATE
		lda	#PSG_IO_B	;read controller 2
		sta	PSG_LATCH_ADDR
		lda	PSG_READ_ADDR
		sta	PAD2STATE
		
		lda	0xC410		;clear controller select line
		lda	#PSG_IO_A	;read controller 1
		sta	PSG_LATCH_ADDR
		lda	PSG_READ_ADDR	;A, Start
		anda	#0b00110000
		lsla			;shift into bits 6 and 7
		lsla
		ora	PAD1STATE
		sta	PAD1STATE
		lda	#PSG_IO_B	;read controller 2
		sta	PSG_LATCH_ADDR
		lda	PSG_READ_ADDR
		anda	#0b00110000
		lsla
		lsla
		ora	PAD2STATE
		sta	PAD2STATE
		lda	0xC418		;set controller select line again

		lda	0xC410		;clear controller select line
		lda	#PSG_IO_A	;read controller 1
		sta	PSG_LATCH_ADDR
		lda	PSG_READ_ADDR	;A, Start
		coma			;invert bits so 1 indicates pressed
		anda	#0b00110000
		lsla			;shift into bits 6 and 7
		lsla
		sta	PAD1STATE
		lda	#PSG_IO_B	;read controller 2
		sta	PSG_LATCH_ADDR
		lda	PSG_READ_ADDR
		coma
		anda	#0b00110000
		lsla
		lsla
		sta	PAD2STATE

		lda	0xC418		;set controller line
		lda	#PSG_IO_A	;read controller 1
		sta	PSG_LATCH_ADDR
		lda	PSG_READ_ADDR	;up, down, left, right, B
		coma
		anda	#0b00111111
		ora	PAD1STATE
		sta	PAD1STATE
		lda	#PSG_IO_B	;read controller 2
		sta	PSG_LATCH_ADDR
		lda	PSG_READ_ADDR
		coma
		anda	#0b00111111
		ora	PAD2STATE
		sta	PAD2STATE

