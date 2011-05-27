; vim:noet:sw=8:ts=8:ai:syn=as6809
; Matt Sarnoff (msarnoff.org/6809) - January 24, 2011
;
;************ PS/2 keyboard routines ************
;Uses the 6522 Versatile Interface Adapter in the following configuration:
;CA1: clock
;PB7: data
;High-to-low transitions on the clock line trigger fast (FIRQ) interrupts.
;Compatible with the I2C routines, but I2C *must* be initialized first.
;
;Sending data to the keyboard is not currently supported.
;
;Implements a very rudimentary circular scancode buffer with no overflow
;checking. If the buffer is full, new scancodes overwrite old ones. (but memory
;outside the scancode buffer is not affected.)
;If you're checking for keypresses at 60 Hz you should never encounter a
;situation where the buffer overflows.

;;; initializes the keyboard system
;;; arguments:	none
;;; returns:	none
;;; destroys:	A,B,X
;;;
;;; Turns on interrupt generation. The F bit in CC must be clear to receive
;;; keyboard interrupts. This should be done by calling KBD_ENABLE; merely
;;; clearing the F bit might cause a pending interrupt (possibly from the
;;; keyboard's init signal after first power-on) to be services, throwing off
;;; the bit counter.
KBD_INIT::	ldx 	#KEYSTATE	;clear keyboard state
1$:		clr	,x+
		cmpx	#KBD_BUFEND
		bls	1$
		lda	#10		;initialize bit counter
		sta	*KBD_BITSLEFT
		ldd	#KBD_BUFSTART	;initialize buffer pointers
		std	*KBD_HEADPTR
		std	*KBD_TAILPTR
		ldd	#KBD_HANDLER	;install interrupt handler
		std	*FIRQVEC
		lda	VIA_PCR
		anda	#0b11111110	;interrupt on CA1 negative edge
		sta	VIA_PCR
		lda	#IER_SET|CA1_INT
		sta	VIA_IER		;enable CA1 interrupt
		rts


;;; enables the keyboard interrupt (FIRQ)
;;; arguments:	none
;;; returns:	none
;;; destroys:	A, clears F in CC
;;;
;;; Don't clear F directly, use this function instead.
KBD_ENABLE::	andcc	#0b10111111	;clear F bit
		lda	#10
		sta	*KBD_BITSLEFT	;reset bit counter in case there was
		rts			;  a pending interrupt


;;; keyboard interrupt handler
;;; typical PS/2 clock is 15 kHz (66.67 us period) so this should be fine
KBD_HANDLER:
	.if 0
		tst	VIA_ORA
		dec	*KBD_BITSLEFT
		bmi	kbh_stopbit
		tst	0xCD00|KBD_BITSLEFT
		;tst	VIA_IRB
		;tst	0xCF00
		rti
kbh_stopbit:	sta	*KBD_SAVE
		lda	#10
		sta	KBD_BITSLEFT
		tst	0xCD00|KBD_BITSLEFT
		;tst	VIA_IRB
		;tst	0xCF00
		tst	0xCE00|'-
		lda	*KBD_SAVE
		rti
	.else
		tst	VIA_ORA		;clear interrupt source
		dec	*KBD_BITSLEFT
		beq	kbh_done	;parity bit, ignore
		bmi	kbh_stopbit	;last bit, store scancode in buffer
		;tst	0xCD00|KBD_BITSLEFT
		sta	*KBD_SAVE	;save A register
		lda	VIA_IRB		;read data bit (bit 7)
		lsla
		ror	*KBD_SCANCODE	;shift into scancode
		lda	*KBD_SAVE	;restore A register
kbh_done:	rti
kbh_stopbit:	sta	*KBD_SAVE	;save A register
		lda	*KBD_SCANCODE	;store scancode
		sta	[KBD_HEADPTR]
		lda	KBD_HEADPTR_L	;advance head pointer
		inca
		anda	#KBD_BUFMASK	;force wraparound
		sta	*KBD_HEADPTR_L
		lda	#10		;reset bit counter
		sta	*KBD_BITSLEFT
		;tst	0xCE00|'-
		lda	*KBD_SAVE	;restore A register
		rti
	.endif

;;; fetch a scancode from the buffer
;;; arguments:	none
;;; returns:	scancode in B or 0 if buffer is empty
;;; destroys:	A
KBD_GETCODE::	ldb	#10
1$:		cmpb	*KBD_BITSLEFT	;wait until a full scancode is processed
		bne	1$
		ldb	*KBD_HEADPTR_L	;is the buffer empty?
		cmpb	*KBD_TAILPTR_L	;(i.e. head and tail are the same)
		beq	bufempty
		ldb	[KBD_TAILPTR]	;buffer not empty, get code
		lda	*KBD_TAILPTR_L	;advance tail pointer
		inca
		anda	#KBD_BUFMASK	;force wraparound
		sta	*KBD_TAILPTR_L
		tstb			;set flags for return
getcodedone:	rts
bufempty:	clrb			;return 0
		rts

