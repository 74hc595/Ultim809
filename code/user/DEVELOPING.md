Developing Applications for Ultim809
====================================

What you'll need
----------------

*  A Unix-like system (Linux, Mac OS X, etc.) You're on your own if you use Windows.
*  A 6809 assembler. I use [ASxxxx](http://shop-pdp.kent.edu/ashtml/asxxxx.htm), and I have included Makefiles for it. It's full-featured, but uses somewhat nonstandard syntax. [asmx](http://xi6.com/projects/asmx/) uses traditional Motorola syntax, but I haven't tried it.
*  The SRecord package, installed through apt-get, MacPorts, or from the [website.](http://srecord.sourceforge.net)
*  I recommend using Vim with the `as6809.vim` syntax highlighting file (in the `code/` directory) and 8 spaces per tab.

6809 assembly language
----------------------
I won't go into the details of 6809 assembly language here. There are very few tutorials available, but the Motorola 6809 Programming Manual is available online [here](http://www.classiccmp.org/dunfield/r/6809prog.pdf) and is a good reference. I have also tried to comment my code as thoroughly as possible so that others might learn from it.

### The basics
There are two 8-bit accumulators, A and B. Together, they make up the 16-bit accumulator D. Supported operations include addition, subtraction, comparison, test, bitwise operations, shifts/rotates, and 8x8 unsigned multiply.

There are two 16-bit index registers, X and Y. They are typically used to hold pointers. All load, store and modify operations can use the addresses stored in X and Y, with optional displacement (by a constant or register value), autoincrement/decrement, and indirection.

There are not one, but _two_ stack pointers, S and U. Both act just like index registers, with the addition of "push" and "pull" instructions. S is the hardware stack pointer, used to store return addresses. You can do whatever you want with U, mostly it's used as a third index register.

The program counter, PC, is 16-bit, and can be used for program-counter-relative addressing when writing position-independent code.

DP is the direct page register, it holds the upper 8 bits of the effective address in direct addressing mode. **On the Ultim809 it should be kept set to 0, see below.**

CC is the condition code register. Condition flags are C (bit 0, carry), V (overflow), Z (zero), N (negative), I (IRQ interrupt inhibit), H (half-carry), F (FIRQ interrupt inhibit) and E (bit 7, entire machine state stacked on interrupt).

Most instructions operate on one register and one memory location (or immediate value). A couple instructions (transfer, exchange) operate on two registers, and some operate directly on memory. The 6809 has plenty of addressing modes, nearly all of which can be used with every instruction. See the programming manual for more information, there are too many to describe here, but they're awesome.

The address space
-----------------
The 6809, like other 8-bit processors, has a 16-bit address bus, and thus a 64K address space. The ROM lives at 0xE000-0xFFFF, and I/O devices are memory mapped in the range 0xC000-0xDFFF. The remaining 48K is RAM.

	0000 +-------------------------+
	     |                         | 0000-007F: system reserved RAM
	     |        User RAM         | 0080-00FF: availble zero-page RAM
	     |     (bank 0, fixed)     | 0100: user program start
	     |                         |
	4000 +-------------------------+
	     |                         |
	     |        User RAM         |
	     |     (bank 1, fixed)     |
	     |                         |
	8000 +-------------------------+
	     |                         |
	     |        User RAM         |
	     |    (selectable bank)    |
	     |                         |
	C000 +-------------------------+
	     |       I/O devices       | C001: bank select register
	     |      (see I/O map)      |
	E000 +-------------------------+
	     |           ROM           |
	     |       (8K EEPROM)       |
	     +-------------------------+

The RAM is divided into 16K banks. Banks 0 and 1 are always present in the lower 32K of the address space. The next 16K ($8000-$BFFF) is a user-selectable bank. The bank can be changed by writing to address $C001. (VIA output register A) A maximum of 256 banks (4 megabytes) are supported. The standard 512K system has 32 banks.

User programs are always loaded at address $0100. They are welcome to place their stack anywhere in user RAM, though I recommended the last address of bank 0 or 1 ($3FFF or $7FFF). **Note that the stack pointer should be initialized to one byte _past_ the last stack byte: i.e. $4000 or $8000.**

Direct page register
--------------------

While the 6502 allows direct addressing only from the zero page, the 6809 allows direct addressing from any of the 256 256-byte pages, controlled by the direct page register DP. For now, **do not mess with DP. Leave it set to 0.** The ROM routines expect DP to be 0, direct addressing is used to save space and cycles. If you're careful, you can mess with DP as long as you set it back to 0 before calling any ROM routines, but **the keyboard interrupt handler expects DP to be 0 as well.** You've been warned.

Interrupts and vectors
----------------------
The 6809 has three hardware interrupts (NMI, IRQ, and FIRQ) and three software interrupts (SWI, SWI2, and SWI3). All six interrupts transfer control to customizable vectors stored in the zero page. Interrupt behavior can be changed by storing interrupt handler addresses to `NMIVEC`, `IRQVEC`, `FIRQVEC`, `SWIVEC`, `SWI2VEC`, and `SWI3VEC`. 

### Hardware interrupts

NMI enters the monitor and enables remote program downloading. It is triggered by pressing the INTERRUPT button.

FIRQ is asserted by the VIA and is used for the keyboard handler. If you wish to use the keyboard and connect another interrupt source to FIRQ, your interrupt handler should call `KBD_HANDLER` to make sure the keyboard data bit is received.

IRQ is used for the TMS9918A VDP's vertical blanking interrupt. When enabled, it is asserted 60 times a second. The VDP's status register must be read to clear the interrupt.

### Software interrupts

The software interrupts are not currently used, but they will be in a future revision of the ROM.

SWI is intended to be used as a breakpoint instruction. It will trap into the monitor, keeping the program running.

SWI2 should be used as a "quit program" instruction. It will return control to the shell.

SWI3 has no planned use. Go nuts.

### Character input/output

The `OUTCH` and `INCH` vectors are used for character input and output routines. They act similar to standard input and output and may be configured to use the screen/keyboard or the serial port.

`OUTCH` is used by all the string/numeric output functions in the ROM.

Calling `UART_IO` will set up `OUTCH` and `INCH` to use the serial port.

The subroutine pointed to by `OUTCH` should take the character to be output in the B register and destroy no other registers.

The subroutine pointed to by `INCH` should return a character in the B register and destroy no other registers. It should block until a character has been received.

Program structure
-----------------

The typical control flow of a graphical application is fairly simple:

*  Set the stack pointer
*  Clear VRAM, turn the display off, and send pattern/color data to the VDP
*  Initialize program variables and data structures
*  Enable the keyboard and vblank interrupts
*  Turn the display on
*  Begin the logic update loop

The logic loop should be used for updating game/program logic. A `sync` instruction at the end of the loop (just before the jump back to the beginning) ensures it is called at a rate of 60 Hz.

The vblank interrupt handler should be used for all writes to video RAM, since there is no need to wait for an access window.

### Multiple assembler files

Since I haven't quite figured out separate assembly/linking with AS6809, the easiest way to assemble multiple files is to `.include` them at the end of the main `.asm` file. If one of the included files is modified, you'll have to rebuild with `make clean all`.

### Text-based programs

If you're making a "command-line" program that uses the screen in 40x24 text mode and the keyboard, you can set everything up with a call to `TEXT_CONSOLE` at the start of the program. All character I/O can then be done with `OUTCH` and `INCH`, and there is no need to directly manipulate video memory. A vblank handler is not installed.

### Program layout

See `stub.asm` and `Makefile_stub` for a new program template.

I/O devices
-----------

The I/O devices are accessed through memory addresses in the range $C000-$DFFF. Here is the full I/O device map:

	$C000-$C00F - 6522A Versatile Interface Adapter
	$C001       - bank select register (VIA port A output register)
	$C400-$C407 - 16550 UART (serial port)
	$C404       - controls status LED color (UART modem control register)
	$C800       - SPI input shift register
	$CC00-$CC01 - TMS9918A Video Display Processor
	$CC02-$CC03 - YM2149 Programmable Sound Generator
	$CC04       - read to select lower 16K of VRAM
	$CC06       - read to clear the controller SELECT lines
	$CC0C       - read to select upper 16K of VRAM
	$CC0E       - read to set the controller SELECT lines
	$D000-$D3FF - external device #1
	$D400-$D7FF - external device #2
	$D800-$DBFF - external device #3
	$DC00-$DFFF - external device #4
	
### 6522A VIA

[Datasheet](http://www.westerndesigncenter.com/wdc/documentation/w65c22.pdf)

The VIA is used mainly by the ROM routines, in most cases you don't need to touch it directly. Port A controls the upper 8 address lines, so writing to the port A output register (address $C001) changes the selected memory bank.

You should not change the Data Direction Registers. Port A should be set to all outputs and Port B should be set to all inputs.

### 16550 UART

[Datasheet](http://www.national.com/ds/PC/PC16550D.pdf)

The UART is initialized on powerup to operate at 38400 baud, 8 data bits, no parity, 1 stop bit. The `UART_INIT` subroutine can be used to reinitialize the UART with a different baud rate. You should pass the appropriate `B*` baud rate constant in the X register.

Calling `UART_IO` sets up the character I/O routines `OUTCH` and `INCH` to use the serial port.

The status LED is controlled by the two general-purpose outputs. `UART_SETLED` is a convenience method for changing the status LED color.

The FIFO, DMA, and interrupt functions are not used. The interrupt line is not connected.

### TMS9918A VDP

[Datasheet](http://www.cs.columbia.edu/~sedwards/papers/TMS9918.pdf)

The VDP has two addresses: the register write address, and the VRAM write address.

`tms9918.asm` in the `rom/` directory contains plenty of subroutines for interacting with the VDP and VRAM. Calling `VDP_CLEAR` at the start of your program is always a good idea to prevent graphics corruption.

`VDP_SET_REGS` sets all 8 control registers from an 8-byte block of memory pointed to by X.

`VDP_LOADPATS` makes it easy to copy 8-byte chunks of data (color table entries, pattern table entries) to VRAM.

`VDP_INITTEXT` automatically places the VDP in 40x24 text mode and copies the text character set to VRAM.

If possible, don't write to VRAM unless the display is off, or you're in the vblank handler. Read the datasheet: when the display is active, the VDP can require up to 8 microseconds before it's ready to write a byte to memory.

It's possible to transfer about 1K of data in the vertical blanking interval (which is 4300 microseconds long). It's enough for an entire name table update if you unroll your loop a whole lot.

The Ultim809 actually has 32K of VRAM, though the VDP can only access 16K at once. Doing an `lda` from `VBANK_LOWER` or `VBANK_UPPER` selects a VRAM bank. Its effectiveness as a double buffer is limited, since you can't write into one bank and have another displayed onscreen.

### YM2149 PSG

[Datasheet](http://www.ym2149.com/ym2149.pdf)

The YM2149 (also known as the AY-3-8910) runs off the 2MHz system clock. It has three channels, each of which can play a square wave, noise, or both. Each channel can either use a 4-bit volume value, or the waveform from the envelope generator.

Helpful subroutines, along with formulas to convert frequencies in Hz to register values, are in the `include/ym2149.asm` file.

The YM2149 is also used to read the controller ports. The two I/O ports should always be configured as inputs.

6809 assembler tips/idioms
--------------------------

This section won't serve as a full 6809 assembler tutorial, it's meant to be a collection of knowledge snippets I accumulated over the course of the project.

### Some index registers are faster than others
`ldy`/`sty` and `lds`/`sts` are one cycle _slower_ than `ldx`/`stx` and `ldu`/`stu`. It's recommended to use U as an index register before Y. `cmpx` is one cycle faster than all the other 16-bit register compares.

### 16-bit shifts and negation

Shift D left one bit:

	lslb
	rola
	
Shift D right one bit, unsigned:

	lsra
	rorb

Shift D right one bit, maintaining sign:

	asra
	rorb
	
Negate D:

	coma
	comb
	addd #1

### Reserve stack space during subroutines
If you run out of registers in a subroutine and need temporary space during a subroutine, use `leas` with a negative constant offset:

	leas -4,s	;reserve 4 bytes of stack space
	;do stuff
	leas 4,s	;restore stack space
	rts
		
### Know your flags

`inc` and `dec` affect the Negative, Zero, and Overflow flags. You can use a branch instruction directly after them.

All `ld` instructions set the Zero and Negative flags. You can use a branch instruction directly after them.

`leax` and `leay` set the Zero flag if the result is zero, `leas` and `leau` do not affect the Zero flag.

`clr` always sets the Carry flag. Use `ld #0` to zero a register without affecting the Carry flag.

### Quick 3-way logic tests
Branch instructions preserve the condition codes, so, for example, the following snippet can test if a number is zero, negative, or positive:

	ldb #somenumber
	beq number_is_zero
	bmi number_is_negative
	;number is positive
	
### Use `lea` instead of `tfr` with index registers
`leax ,y` is two cycles faster than `tfr y,x`.

### Use `lea` for 16-bit increments/decrements
`leax -1,x` will decrement X. `leax` and `leay` also set the Zero flag, so if you need a 16-bit loop counter, use X and Y instead of D.

### Tail calls
If the last instruction of a subroutine is a call to another subroutine, use `bra` or `jmp` instead of `bsr`/`jsr`. Also consider grouping subroutines together so one can "fall through" to another.

### Return from subroutine and restore registers with one instruction
`rts` is equivalent to `puls pc`. PC is always the last register pulled in a sequence, so if you had to push register values on the stack at the start of a subroutine, they can be restored along with the program counter. So instead of

	pshs d,x,y
	;do stuff here
	puls d,x,y
	rts

just do

	pshs d,x,y
	;do stuff here
	puls d,x,y,pc

This saves one byte and three cycles.

### For loops

If you have a free accumulator register, use it as the loop counter:

		lda  #5
	loop:
		;do stuff
		deca
		bne  loop
		
This works for up to 256 iterations: if A is 0, the `deca` will cause a wraparound and the loop will execute 256 times.

If you need both A and B during the loop, put the loop counter on the stack:

		lda  #5
		pshs a
	loop:
		;do stuff
		dec  ,s
		bne  loop
	done:
		leas 1,s
		
If you need a 16-bit loop counter, use X or Y, since `leax` and `leay` affect the Zero flag.

### Zero-terminated string/list processing
If you need to iterate through a list of characters/16-bit integers and stop when a zero is found, use autoincrementing address mode. For example, a routine to copy a null-terminated string pointed to by X to memory pointed to by Y:

	loop:
		ldb  ,x+
		beq  done
		stb  ,y+
		bra  loop

### Use constant offset indexing for data structures
Let's say X points to an array of 4-byte ordered pairs: a 2-byte x coordinate and a 2-byte y coordinate. Use `.equ` statements to give field names to structure offsets:

	xcoord		.equ 0
	ycoord		.equ 2
	POINT_SIZE	.equ 4
	
Now let's say you had a point in U and wanted to add its x and y coordinates to all points in the array pointed to by X. You could do something like this:

	loop:
		ldd  xcoord,x
		addd xcoord,u
		std  xcoord,x
		ldd  ycoord,x
		addd ycoord,u
		std  ycoord,x
		leax POINT_SIZE,x
		cmpx #POINTS_END
		bne  loop
		
### Table lookups
Indexed addressing with register offset is great for performing table lookups. For example, to get the byte in a table specified by the value in A:

	ldu  #TABLE
	ldb  a,u
	
A can be multiplied by 2 to perform a lookup in a table of 2-byte values:
	
	ldu  #TABLE
	lsla
	ldd  a,u
	
Note that register offsets are signed, so the first example only works with tables of 128 entries or less, and the second only works with tables of 64 entries or less.

There are a couple ways to perform a lookup in a table greater than 128 bytes and less than 256 bytes. One is to put the table pointer in X, the table offset in B, and use `abx`, which performs an unsigned addition:

	ldx  #TABLE
	abx
	ldb  b,x
	
The other is to shift B one bit left into A and use a 16-bit offset:

	ldu  #TABLE
	clra
	lslb
	rola
	ldb  d,u
	
However, this method is more expensive.

If your table is exactly 256 bytes, you can use an 8-bit register offset if you arrange your table in a clever way to take advantage of two's complement arithmetic. The first byte in the table will correspond to an offset of 128 (%10000000 or -128 in two's complement) The 129th byte will correspond to an offset of 0, so you should set your label to point to this byte in the table instead of the first. An example, using the identity table:

		.fcb 128,129,130,131
		;...
		;.fcb 252,253,254,255
	TABLE:
		.fcb 0,1,2,3
		;...
		.fcb 124,125,126,127
		
### Swap the bytes in a 16-bit number

	ldd  NUMBER
	exg  a,b
	std  NUMBER

Even better, if the source of the 16-bit numbers is a table, store them byte-swapped if possible!

### Set a YM2149 register with one instruction
When setting a register in the YM2149, first you write the register number to `PSG_LATCH_ADDR`, then the register value to `PSG_WRITE_ADDR`. However, since these addresses are right next to each other, both can be set with a 16-bit write:

	lda  #REGISTER_NUMBER
	ldb  #REGISTER_VALUE
	std  PSG
	
Or, combine both values with bitwise operations:

	ldd  #(REGISTER_NUMBER<<8)|REGISTER_VALUE
	std  PSG
	
### Set the VDP VRAM address
The TMS9918A has a strange memory addressing scheme: to write to or read from VRAM, the address must first be set, and it autoincrements with each read/write. When setting the VRAM address, two bytes must be written to the VDP register: the 14-bit VRAM address, with the secondmost-significant-bit set to 1, little-endian. The VDP can only receive a byte every 2 microseconds (4 cycles), so a 16-bit store instruction can't be used. Instead, write both bytes separately:

	ldd  #NEW_VRAM_ADDRESS
	ora  #0x40
	stb  VDP_REG
	sta  VDP_REG
	
The `VRAM` define is included to make things easier to understand:

	ldd	 #VRAM|NEW_VRAM_ADDRESS
	stb  VDP_REG
	sta  VDP_REG
	
### Sometimes it's better to not restore register values
Let's say you're writing a subroutine to process a chunk of data, like a zero-terminated string. You have a subroutine that takes a pointer to a zero-terminated string in X:

	SUBROUTINE:
		pshs x
	loop:
		ldb  ,x+
		beq  done
		;do stuff
		bra  loop
	done:
		puls x,pc
		
X is advanced inside the subroutine, but restored when it returns. Now what happens if you have to call this subroutine multiple times in a row?

	ldx  #string1
	jsr  SUBROUTINE
	ldx  #string2
	jsr  SUBROUTINE
	ldx  #string3
	jsr  SUBROUTINE
	;...
	string1: .asciz "This is string one"
	string2: .asciz "This is string two"
	string3: .asciz "This is string three"
	
If we modify `SUBROUTINE` to **not** restore X, it will point to the start of the next string on return, so we don't have to re-set X, and can just do this:

	ldx  #string1
	jsr  SUBROUTINE
	jsr  SUBROUTINE
	jsr  SUBROUTINE
	
If you're calling the same subroutine a bunch of times, it can be _faster_ to store the subroutine address in an index register:

	ldx  #string1
	ldu  #SUBROUTINE
	jsr  ,u
	jsr  ,u
	jsr  ,u

### Disable and enable interrupts
The 6809 doesn't have explicit enable/disable interrupt instructions. Instead, use the `orcc` and `andcc` instructions to directly modify the bits in the CC register:

	orcc  #0b01010000 ;disable interrupts (set bits F and I)
	andcc #0b10101111 ;enable interrupts (clear bits F and I)