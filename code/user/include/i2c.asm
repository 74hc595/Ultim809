; vim:noet:sw=8:ts=8:ai:syn=as6809
; Matt Sarnoff (msarnoff.org/6809) - September 15, 2010
;
;************ I2C bit-banging routines ************
;Uses the 6522 Versatile Interface Adapter in the following configuration:
;Port B pin 0: SDA
;Port B pin 1: SCL
;All other port B pins should be inputs or unused
;
;I2C is open-drain, so:
; - logic high is output by leaving the line pulled up to Vcc (DDR bit = 0)
; - logic low is output by pulling the line to ground (DDR bit = 1)
;
;Port B output register is always all zeros.


;************ Definitions ************

SDA		.equ	0b01
SCL		.equ	0b10

;;; initializes the I2C system
;;; arguments:	none
;;; returns:	none
;;; destroys:	A
I2C_INIT::	clr	VIA_DDRB	;all pins inputs
		clr	VIA_ORB		;all pins low when in output mode
		rts


;;; send start condition (pull SDA low while SCL stays high)
;;; SCL and SDA must already be high
;;; arguments:	none
;;; returns:	none
;;; destroys:	A
I2C_START::	lda	#SDA		;SDA becomes an output (pulled low)
		sta	VIA_DDRB
		rts			;now SCL is high and SDA is low


;;; send stop condition (pull SDA high while SCL stays high)
;;; SCL and SDA must be low
;;; arguments:	none
;;; returns:	none
;;; destroys:	A
I2C_STOP::	lda	#SDA|(~SCL)	;bring SCL high, leaving SDA low
		sta	VIA_DDRB	;now SCL is high
		clr	VIA_DDRB	;now bring SDA high
		rts


;;; send a byte
;;; SCL must be high, SDA must be low (start condition already sent)
;;; arguments:	byte in B
;;; returns:	none
;;; destroys:	A
I2C_WRITE::	pshs	dp,cc
		orcc	#0b01010000	;disable interrupts
		lda	#VIA_PAGE	;so nothing messes up DP
		tfr	a,dp
		comb			;SDA output is inverted
		lda	#SCL|SDA	;will set SCL low, keeping SDA low
; send bit 7
		lslb			;get MSB out of A, into carry flag
		sta	*VIA_DDRB_D	;set SCL and SDA low (C not affected)
		anda	#~SDA		;get data bit ready (C not affected)
		adca	#0		;set data bit from carry flag
		sta	*VIA_DDRB_D	;set data bit
		anda	#~SCL		;will bring SCL high
		sta	*VIA_DDRB_D	;SCL rising edge (slave reads data bit)
		ora	#SCL		;will bring SCL low
		nop			;wait a little for slave to read bit
; send bit 6
		lslb
		sta	*VIA_DDRB_D	;SCL falling edge
		anda	#~SDA
		adca	#0
		sta	*VIA_DDRB_D	;SDA set
		anda	#~SCL
		sta	*VIA_DDRB_D	;SCL rising edge
		ora	#SCL
		nop
; send bit 5
		lslb
		sta	*VIA_DDRB_D	;SCL falling edge
		anda	#~SDA
		adca	#0
		sta	*VIA_DDRB_D	;SDA set
		anda	#~SCL
		sta	*VIA_DDRB_D	;SCL rising edge
		ora	#SCL
		nop
; send bit 4
		lslb
		sta	*VIA_DDRB_D	;SCL falling edge
		anda	#~SDA
		adca	#0
		sta	*VIA_DDRB_D	;SDA set
		anda	#~SCL
		sta	*VIA_DDRB_D	;SCL rising edge
		ora	#SCL
		nop
; send bit 3
		lslb
		sta	*VIA_DDRB_D	;SCL falling edge
		anda	#~SDA
		adca	#0
		sta	*VIA_DDRB_D	;SDA set
		anda	#~SCL
		sta	*VIA_DDRB_D	;SCL rising edge
		ora	#SCL
		nop
; send bit 2
		lslb
		sta	*VIA_DDRB_D	;SCL falling edge
		anda	#~SDA
		adca	#0
		sta	*VIA_DDRB_D	;SDA set
		anda	#~SCL
		sta	*VIA_DDRB_D	;SCL rising edge
		ora	#SCL
		nop
; send bit 1
		lslb
		sta	*VIA_DDRB_D	;SCL falling edge
		anda	#~SDA
		adca	#0
		sta	*VIA_DDRB_D	;SDA set
		anda	#~SCL
		sta	*VIA_DDRB_D	;SCL rising edge
		ora	#SCL
		nop
; send bit 0
		lslb
		sta	*VIA_DDRB_D	;SCL falling edge
		anda	#~SDA
		adca	#0
		sta	*VIA_DDRB_D	;SDA set
		anda	#~SCL
		sta	*VIA_DDRB_D	;SCL rising edge
		ora	#SCL
		nop
		nop
		sta	*VIA_DDRB_D	;SCL falling edge
; release SDA so slave can send ACK bit
		anda	#~SDA		;bring SDA high
		sta	*VIA_DDRB_D
		anda	#~SCL
		sta	*VIA_DDRB_D	;SCL rising edge
		nop
		nop
		ora	#SCL
		sta	*VIA_DDRB_D	;SCL falling edge
; bring SDA low
		ora	#SDA
		sta	*VIA_DDRB_D
; SCL and SDA are now both low, stop condition may be sent
		puls	dp,cc,pc


;;; receive a byte, send ACK to the slave
;;; arguments:	none
;;; returns:	byte in B
;;; destroys:	A
I2C_READ_ACK::	pshs	dp,cc
		orcc	#0b01010000	;disable interrupts
		lda	#VIA_PAGE	;so nothing messes up DP
		tfr	a,dp
		bsr	I2C_READ	;read byte
; SCL is low and SDA is high, pull SDA low to send ACK
		lda	#SCL|SDA
		sta	*VIA_DDRB_D	;pull SDA low
		anda	#~SCL
		sta	*VIA_DDRB_D	;SCL rising edge
		nop
		nop
		ora	#SCL
		sta	*VIA_DDRB_D	;SCL falling edge
; SCL and SDA are now low
		puls	dp,cc,pc


;;; receive a byte, send NACK to the slave
;;; arguments:	none
;;; returns:	byte in B
;;; destroys:	A
I2C_READ_NACK::	pshs	dp,cc
		orcc	#0b01010000	;disable interrupts
		lda	#VIA_PAGE	;so nothing messes up DP
		tfr	a,dp
		bsr	I2C_READ	;read byte

; SCL is low, leave SDA high to send NACK
		clra
		sta	*VIA_DDRB_D	;SCL rising edge
		nop
		nop
		ora	#SCL
		sta	*VIA_DDRB_D	;SCL falling edge
		ora	#SDA
		sta	*VIA_DDRB_D	;pull SDA low, to prepare for stop
; SCL and SDA are now low
		puls	dp,cc,pc


;;; receive a byte, without sending ACK or NACK
;;; direct page register must be properly set to VIA_PAGE
;;; arguments:	none
;;; returns:	byte in B
;;; destroys:	A
I2C_READ:	clrb
; pull SCL low (prepare for first clock)
		lda	*VIA_DDRB_D
		ora	#SCL
		sta	*VIA_DDRB_D	;SCL falling edge
; SDA is still an input, but SCL is now an output
; release SDA so slave can set data bit
		anda	#~SDA
		sta	*VIA_DDRB_D	;SDA released

; clock in bit 7
		clr	*VIA_DDRB_D	;SCL rising edge
		lda	*VIA_IRB_D	;read data line
		lsra			;shift data into carry bit
		lda	#SCL
		sta	*VIA_DDRB_D	;SCL falling edge
		rolb			;shift carry bit into result
		nop
; clock in bit 6
		clr	*VIA_DDRB_D	;SCL rising edge
		lda	*VIA_IRB_D
		lsra
		lda	#SCL
		sta	*VIA_DDRB_D	;SCL falling edge
		rolb
		nop
; clock in bit 5
		clr	*VIA_DDRB_D	;SCL rising edge
		lda	*VIA_IRB_D
		lsra
		lda	#SCL
		sta	*VIA_DDRB_D	;SCL falling edge
		rolb
		nop
; clock in bit 4
		clr	*VIA_DDRB_D	;SCL rising edge
		lda	*VIA_IRB_D
		lsra
		lda	#SCL
		sta	*VIA_DDRB_D	;SCL falling edge
		rolb
		nop
; clock in bit 3
		clr	*VIA_DDRB_D	;SCL rising edge
		lda	*VIA_IRB_D
		lsra
		lda	#SCL
		sta	*VIA_DDRB_D	;SCL falling edge
		rolb
		nop
; clock in bit 2
		clr	*VIA_DDRB_D	;SCL rising edge
		lda	*VIA_IRB_D
		lsra
		lda	#SCL
		sta	*VIA_DDRB_D	;SCL falling edge
		rolb
		nop
; clock in bit 1
		clr	*VIA_DDRB_D	;SCL rising edge
		lda	*VIA_IRB_D
		lsra
		lda	#SCL
		sta	*VIA_DDRB_D	;SCL falling edge
		rolb
		nop
; clock in bit 0
		clr	*VIA_DDRB_D	;SCL rising edge
		lda	*VIA_IRB_D
		lsra
		lda	#SCL
		sta	*VIA_DDRB_D	;SCL falling edge
		rolb
		rts

