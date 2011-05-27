; vim:noet:sw=8:ts=8:ai:syn=as6809
	.ifndef	_HARDWARE_INC_
	.define _HARDWARE_INC_

;************ Memory ************
RAMSTART	.gblequ	0x0000
RAMEND		.gblequ	0x7FFF
XRAMSTART	.gblequ	0x8000
XRAMEND		.gblequ	0xBFFF
STKSTART	.gblequ	RAMEND
ROMSTART	.gblequ	0xE000
USERPROG_ORG	.gblequ	0x0100		;entry point for user programs
ROMDP		.gblequ	0x00		;ROM requires direct page to be 0
ROMSTKSTART	.gblequ	(ROMDP<<8)+64	;ROM stack
SYSRAM		.gblequ	0x02		;start of system-used RAM
					;(bytes 0x0000 and 0x0001 unused)


;************ I/O addresses ************

VIA		.gblequ	0xC000		;6522 Versatile Interface Adapter
VIA_ORB		.gblequ	VIA		;Output Register B
VIA_IRB		.gblequ	VIA		;Input Register B
VIA_ORA		.gblequ	VIA+0x1		;Output Register A
VIA_IRA		.gblequ	VIA+0x1		;Input Register A
VIA_DDRB	.gblequ	VIA+0x2		;Data Direction Register B
VIA_DDRA	.gblequ	VIA+0x3		;Data Direction Register A
VIA_T1CL	.gblequ	VIA+0x4		;Timer 1 Counter Low
VIA_T1CH	.gblequ	VIA+0x5		;Timer 1 Counter High
VIA_T1LL	.gblequ	VIA+0x6		;Timer 1 Latch Low
VIA_T1LH	.gblequ	VIA+0x7		;Timer 1 Latch High
VIA_T2CL	.gblequ	VIA+0x8		;Timer 2 Counter Low
VIA_T2CH	.gblequ	VIA+0x9		;Timer 2 Counter High
VIA_SR		.gblequ	VIA+0xA		;Shift Register
VIA_ACR		.gblequ	VIA+0xB		;Auxiliary Control Register
VIA_PCR		.gblequ	VIA+0xC		;Peripheral Control Register
VIA_IFR		.gblequ	VIA+0xD		;Interrupt Flag Register
VIA_IER		.gblequ	VIA+0xE		;Interrupt Enable Register

; direct-page VIA addresses
VIA_PAGE	.equ	VIA>>8
VIA_L		.equ	VIA&0xFF
VIA_ORB_D	.equ	VIA_L
VIA_IRB_D	.equ	VIA_L
VIA_ORA_D	.equ	VIA_L+0x1
VIA_IRA_D	.equ	VIA_L+0x1
VIA_DDRB_D	.equ	VIA_L+0x2
VIA_DDRA_D	.equ	VIA_L+0x3

PAGE		.gblequ	VIA_ORA		;extended RAM page register

; Peripheral Control Register bitfields
CB2_IN_NEG	.gblequ	0b00000000	;CB2 input, negative active edge
CB2_IN_NEG_IND	.gblequ	0b00100000	;CB2 input, neg, independent interrupt
CB2_IN_POS	.gblequ	0b01000000	;CB2 input, positive active edge
CB2_IN_POS_IND	.gblequ	0b01100000	;CB2 input, pos, independent interrupt
CB2_OUT_HS	.gblequ	0b10000000	;CB2 handshake output
CB2_OUT_PULSE	.gblequ	0b10100000	;CB2 pulse output
CB2_OUT_LOW	.gblequ	0b11000000	;CB2 low output
CB2_OUT_HIGH	.gblequ	0b11100000	;CB2 high output
CB1_NEG		.gblequ	0b00000000	;Interrupt on CB1 negative edge
CB1_POS		.gblequ	0b00010000	;Interrupt on CB1 positive edge
CA2_IN_NEG	.gblequ	0b00000000	;CA2 input, negative active edge
CA2_IN_NEG_IND	.gblequ	0b00000010	;CA2 input, neg, independent interrupt
CA2_IN_POS	.gblequ	0b00000100	;CA2 input, positive active edge
CA2_IN_POS_IND	.gblequ	0b00000110	;CA2 input, pos, independent interrupt
CA2_OUT_HS	.gblequ	0b00001000	;CA2 handshake output
CA2_OUT_PULSE	.gblequ	0b00001010	;CA2 pulse output
CA2_OUT_LOW	.gblequ	0b00001100	;CA2 low output
CA2_OUT_HIGH	.gblequ	0b00001110	;CA2 high output
CA1_NEG		.gblequ	0b00000000	;Interrupt on CA1 negative edge
CA1_POS		.gblequ	0b00000001	;Interrupt on CA1 positive edge

; Auxiliary Control Register bitfields
T1_INT_TIMED	.gblequ	0b00000000	;Timed interrupt when T1 is loaded
T1_INT_CONT	.gblequ	0b01000000	;Continuous interrupts
T1_INT_TIMED_1S	.gblequ	0b10000000	;Timed interrupt, PB7 one-shot output
T1_INT_CONT_SQ	.gblequ	0b11000000	;Continuous interrupts, PB7 square wave
T2_INT_TIMED	.gblequ	0b00000000	;T2 timed interrupt
T2_COUNT_PB6	.gblequ	0b00100000	;T2 count down with pulses on PB6
SR_OFF		.gblequ	0b00000000	;Shift register disabled
SR_IN_T2	.gblequ	0b00000100	;Shift in under T2 control
SR_IN_PHI2	.gblequ	0b00001000	;Shift in under PHI2 control
SR_IN_EXT	.gblequ	0b00001100	;Shift in under CB1 control
SR_OUT_T2_FREE	.gblequ	0b00010000	;Shift out free running at T2 rate
SR_OUT_T2	.gblequ	0b00010100	;Shift out at T2 rate
SR_OUT_PHI2	.gblequ	0b00011000	;Shift out at PHI2 rate
SR_OUT_EXT	.gblequ	0b00011100	;Shift out under CB1 control
PB_LATCH_OFF	.gblequ	0b00000000	;Disable port B input latching
PB_LATCH_ON	.gblequ	0b00000010	;Enable port B input latching
PA_LATCH_OFF	.gblequ	0b00000000	;Disable port A input latching
PA_LATCH_ON	.gblequ	0b00000001	;Enable port A input latching

; Interrupt Flag Register and Interrupt Enable Register bitfields
ANY_INT		.gblequ	0b10000000	;Any interrupt
T1_INT		.gblequ	0b01000000	;T1 timeout
T2_INT		.gblequ	0b00100000	;T2 timeout
CB1_INT		.gblequ	0b00010000	;CB1 active edge
CB2_INT		.gblequ	0b00001000	;CB2 active edge
SR_INT		.gblequ	0b00000100	;8 bits shifted out
CA1_INT		.gblequ	0b00000010	;CA1 active edge
CA2_INT		.gblequ	0b00000001	;CA2 active edge
IER_CLR		.gblequ	0b00000000	;1 bits specify interrupts to clear
IER_SET		.gblequ	0b10000000	;1 bits specify interrupts to set

UART		.gblequ	0xC400		;16C550 UART
UART_RHR	.gblequ	UART+0		;receive holding register
UART_THR	.gblequ	UART+0		;transmit holding register
UART_IER	.gblequ	UART+1		;interrupt enable register
UART_ISR	.gblequ	UART+2		;interrupt status register
UART_FCR	.gblequ	UART+2		;FIFO control register
UART_LCR	.gblequ	UART+3		;line control register
UART_MCR	.gblequ	UART+4		;modem control register
UART_LSR	.gblequ	UART+5		;line status register
UART_MSR	.gblequ	UART+6		;modem status register
UART_SPR	.gblequ	UART+7		;scratchpad register
UART_DLL	.gblequ	UART+0		;divisor latch LSB
UART_DLM	.gblequ	UART+1		;divisor latch MSB

VDP		.gblequ	0xCC00		;TMS9918A Video Display Processor
VDP_VRAM	.gblequ	VDP+0		;used for VRAM reads/writes
VDP_REG		.gblequ	VDP+1		;control registers/address latch
VBANK_LOWER	.gblequ	VDP+0x4		;read to select lower 16K of VRAM
VBANK_UPPER	.gblequ	VDP+0xC		;read to select upper 16K of VRAM
VRAM		.gblequ	0x4000		;high bits of VRAM address

PSG		.gblequ	0xCC02		;YM2149 Programmable Sound Generator
PSG_LATCH_ADDR	.gblequ	PSG		;address latch
PSG_WRITE_ADDR	.gblequ	PSG+1		;write
PSG_READ_ADDR	.gblequ	PSG		;read

PSG_A_FREQL	.gblequ	0x00		;tone generator A frequency (low 8 bits)
PSG_A_FREQH	.gblequ	0x01		;tone generator A frequency (high 4 bits)
PSG_B_FREQL	.gblequ	0x02		;tone generator B frequency (low 8 bits)
PSG_B_FREQH	.gblequ	0x03		;tone generator B frequency (high 4 bits)
PSG_C_FREQL	.gblequ	0x04		;tone generator C frequency (low 8 bits)
PSG_C_FREQH	.gblequ	0x05		;tone generator C frequency (high 4 bits)
PSG_NOISE_FREQ	.gblequ	0x06		;noise generator frequency (low 5 bits)
PSG_CTRL	.gblequ	0x07		;I/O port and mixer control
PSG_A_AMPL	.gblequ	0x08		;channel A amplitude (4 bits), envelope enable
PSG_B_AMPL	.gblequ	0x09		;channel B amplitude (4 bits), envelope enable
PSG_C_AMPL	.gblequ	0x0A		;channel C amplitude (4 bits), envelope enable
PSG_ENV_FREQL	.gblequ	0x0B		;envelope frequency (low 8 bits)
PSG_ENV_FREQH	.gblequ	0x0C		;envelope frequency (high 8 bits)
PSG_ENV_SHAPE	.gblequ	0x0D		;envelope shape (low 4 bits)
PSG_IO_A	.gblequ	0x0E		;I/O port A data
PSG_IO_B	.gblequ	0x0F		;I/O port B data

;**** PSG control register (0x07) bits ****
; (bitwise-OR them together)
TONE_NONE	.gblequ	0b00000111
TONE_A		.gblequ	0b00000110
TONE_B		.gblequ	0b00000101
TONE_C		.gblequ	0b00000011
TONE_AB		.gblequ	0b00000100
TONE_AC		.gblequ	0b00000010
TONE_BC		.gblequ	0b00000001
TONE_ABC	.gblequ	0b00000000
NOISE_NONE	.gblequ	0b00111000
NOISE_A		.gblequ	0b00110000
NOISE_B		.gblequ	0b00101000
NOISE_C		.gblequ	0b00011000
NOISE_AB	.gblequ	0b00100000
NOISE_AC	.gblequ	0b00010000
NOISE_BC	.gblequ	0b00001000
NOISE_ABC	.gblequ	0b00000000
IO_A_OUTPUT	.gblequ	0b01000000
IO_B_OUTPUT	.gblequ	0b10000000
IO_AB_OUTPUTS	.gblequ	0b11000000

;**** PSG envelope enable bit (registers 0x08, 0x09, 0x0A)
ENV_ENABLE	.gblequ	0b00010000

;**** Controllers (attached to PSG I/O ports) ****
; Pin 7 (SELECT) of the controller ports is controlled by a latch
; Used for reading Sega 3-button and 6-button controllers
CTLR_SET_SELECT	.gblequ	0xCC0E	;read from this address to set SELECT line
CTLR_CLR_SELECT	.gblequ	0xCC06	;read from this address to clear SELECT line

; 3-button controller button masks
BTN_UP		.gblequ	0b00000001
BTN_DOWN	.gblequ	0b00000010
BTN_LEFT	.gblequ	0b00000100
BTN_RIGHT	.gblequ	0b00001000
BTN_B		.gblequ	0b00010000	;the button on 1-button joysticks
BTN_C		.gblequ	0b00100000
BTN_A		.gblequ	0b01000000
BTN_START	.gblequ	0b10000000
BTN_ANY		.gblequ	BTN_A|BTN_B|BTN_C|BTN_START

;************ UART baud rate divisors ************
; (little-endian: computed for 1.8432MHz clock crystal)
B50		.gblequ	0x0009	;2304
B75		.gblequ	0x0006	;1536
B150		.gblequ	0x0003	;768
B300		.gblequ	0x8001	;384
B600		.gblequ	0xC000	;192
B1200		.gblequ	0x6000	;96
B2400		.gblequ	0x1C00	;28
B4800		.gblequ	0x1800	;24
B7200		.gblequ	0x1000	;16
B9600		.gblequ	0x0C00	;12
B19200		.gblequ	0x0600	;6
B38400		.gblequ	0x0300	;3
B57600		.gblequ	0x0200	;2
B115200		.gblequ	0x0100	;1


;************ LED colors ************
LED_OFF		.gblequ	0b1100
LED_RED		.gblequ	0b1000
LED_GREEN	.gblequ	0b0100
LED_YELLOW	.gblequ	0b0000


;************ Console escape codes ************
ESC_CLRSCR	.gblequ	0xFF
ESC_CLRLINE	.gblequ	0xFE


;************* Common characters ************
NLCHAR		.gblequ	0x0A
CRCHAR		.gblequ	0x0D
BACKSPACECHAR	.gblequ	0x08
DELETECHAR	.gblequ	0x7F

	.endif
