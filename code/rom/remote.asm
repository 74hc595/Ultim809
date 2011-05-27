; vim:noet:sw=8:ts=8:ai:syn=as6809
; Matt Sarnoff (msarnoff.org/6809) - December 7, 2010

;************ Remote debugger/monitor ************
;
; Uses a simplified protocol, inspired by on NoICE's serial protocol
; Can be used for program uploading and ROM flashing

; commands
FN_READ_MEM	.equ	0xFE
FN_WRITE_MEM	.equ	0xFD
FN_RUN_TARGET	.equ	0xFA
FN_ROMLD_START	.equ	0xF3		;causes monitor to be relocated into RAM
FN_ROMLD_DONE	.equ	0xF2		;jumps back to monitor in ROM

; monitor uses the zero page
MONSTKSTART	.equ	0x00FF
MONPAGE		.equ	0x00

MONVARSTART	.equ	0x50		;start of monitor variables
STACKFRAME	.equ	MONVARSTART	;saved stack pointer
COUNT		.equ	MONVARSTART+2
RELOC_DEST	.equ	0x0100		;destination when relocated into RAM

; the monitor is always placed at a fixed location,
; so it can be resumed after the ROM has been rewritten
; must be entered from an interrupt that pushes all registers on stack
MONSTART	.equ	0xFE40

	.org	MONSTART
REMOTEMONITOR::	orcc	#0b01010000	;disable all interrupts
		lda	#MONPAGE	;reset direct page register
		tfr	a,dp
		sts	*STACKFRAME	;save stack pointer
		lds	#MONSTKSTART+1	;enable the monitor stack
		ldb	#LED_YELLOW
		stb	UART_MCR
; set up text mode video, print ready message
		lda	VBANK_LOWER
		jsr	VDP_INITTEXT
		ldd	#TEXT_NAMETABLE+0
		ldx	#monreadystr
		jsr	VDP_PRINTSTR
		jsr	VDP_TEXT_ON

RELOC_START	.equ	.
monitorloop:	bsr	serrecv
		cmpb	#FN_READ_MEM
		beq	readmem
		cmpb	#FN_WRITE_MEM
		lbeq	writemem
		cmpb	#FN_RUN_TARGET
		lbeq	runtarget
		cmpb	#FN_ROMLD_START
		lbeq	relocate
		cmpb	#FN_ROMLD_DONE
		lbeq	romreturn
		bra	cmderror	;unrecognized command

; wait for a byte from the serial port, break on error
; byte returned in B
serrecv:	ldb	UART_LSR
		bitb	#0b10001110	;check for errors
		bne	sererror
		bitb	#0b00000001	;no error? wait for RDR full
		beq	serrecv
		ldb	UART_RHR	;get byte
		rts

; on error, print message and freeze
sererrorstr:	.asciz	"RECEIVE ERROR "
sererror:	pshs	b
		leax	sererrorstr,pcr
printerror:	lbsr	mon_printstr
		puls	b
		lbsr	mon_printhexb
		ldb	#LED_RED	;error, red LED
		stb	UART_MCR
		bra	.		;infinite loop

cmderrorstr:	.asciz	"BAD COMMAND "
cmderror:	pshs	b
		leax	cmderrorstr,pcr
		bra	printerror


; send the byte in B to the serial port
sersend:	lda	#0b00100000
sersendcheck:	bita	UART_LSR	;transmit holding register ready?
		beq	sersendcheck
		stb	UART_THR	;send byte
		rts
		
; read bytes from memory and send them over the serial port
; byte 1: memory address MSB
; byte 2: memory address LSB
; byte 3: number of bytes to read
readmem:	bsr	serrecv		;msb
		tfr	b,a
		bsr	serrecv		;lsb
		tfr	d,x		;address now in X
		bsr	serrecv
		stb	*COUNT		;byte count
1$:		ldb	,x+		;get byte
		bsr	sersend		;send byte
		dec	*COUNT		;decrement count
		bne	1$
		lbra	monitorloop

; write bytes from the serial port to memory
; byte 1: memory address MSB
; byte 2: memory address LSB
; byte 3: number of bytes to write
; sends back 1 after all bytes written
writemem:	bsr	serrecv		;msb
		tfr	b,a
		bsr	serrecv		;lsb
		tfr	d,x		;address now in X
		bsr	serrecv
		stb	*COUNT		;byte count
1$:		bsr	serrecv		;get byte
		stb	,x+		;store byte
		dec	*COUNT		;decrement count
		bne	1$
2$:		cmpb	-1,x		;wait until last write finishes
		bne	2$		;  (for EEPROM programming)
		ldb	UART_MCR
		eorb	#0b1100		;flash LED yellow and print address
		stb	UART_MCR
		ldd	#(VRAM|TEXT_NAMETABLE+40)
		stb	VDP_REG
		sta	VDP_REG
		tfr	x,d
		bsr	mon_printhexw
		ldb	#1		;send back 1 on success
		bsr	sersend
		lbra	monitorloop

; run starting at address, no registers are restored
; byte 1: memory address MSB
; byte 2: memory address LSB
runtarget:	lbsr	serrecv		;msb
		tfr	b,a
		lbsr	serrecv		;lsb
		tfr	d,pc		;set new program counter

; relocate the monitor into RAM, so that the ROM may be overwritten
; sends back 1 on success
relocate:	ldx	#RELOC_START
		ldu	#RELOC_DEST
1$:		ldd	,x++
		std	,u++
		cmpx	#RELOC_END
		blo	1$
		ldb	#1
		bsr	sersend
		jmp	RELOC_DEST	;jump to monitor loop in RAM

; return to the monitor in ROM
romreturn:	jmp	monitorloop	;absolute jump to ROM


; relocatable copies of some text output routines
mon_printstr:	ldd	#(VRAM|TEXT_NAMETABLE)	;always print at (0,0)
		stb	VDP_REG
		sta	VDP_REG
1$:		ldb	,x+
		beq	prdone
		stb	VDP_VRAM
		bra	1$
prdone:		rts

mon_printhexw:	pshs	b		;save lsb
		tfr	a,b
		bsr	mon_printhexb	;print msb
		puls	b		;fall through, print lsb

mon_printhexb:	pshs	b
		lsrb
		lsrb
		lsrb
		lsrb
		bsr	mon_printhexd
		puls	b
		;fall through and print lsd

mon_printhexd:	andb	#0b00001111	;lds only
		orb	#'0
		cmpb	#'9+1		;decimal digit?
		blo	mon_printd	;if so, print it
		addb	#7		;no, add offset
mon_printd:	stb	VDP_VRAM	;print digit
		rts




	.if 0

mon_printhexb:	tfr	b,a
		lsrb
		lsrb
		lsrb
		lsrb
		anda	#0x0f
		leau	monhexchars,pcr
		ldb	b,u
		stb	VDP_VRAM
		ldb	a,u
		stb	VDP_VRAM
		rts
monhexchars:	.fcc	"0123456789ABCDEF"
		
mon_printhexw:	pshs	b
		tfr	a,b
		bsr	mon_printhexb
		puls	b
		bra	mon_printhexb
	.endif


RELOC_END	.equ	.
RELOC_LEN	.equ	RELOC_END-RELOC_START

monreadystr:	.asciz	"Remote ready."
