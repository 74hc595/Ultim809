Ultim809 User Programs
======================

These are some of the application programs I have written for Ultim809. Some are incomplete, but they demonstrate all the functionality of the machine.

For information on writing your own programs, see `DEVELOPING.md`.

The ser09 utility can be used to send programs to Ultim809. Connect a 5-volt FTDI USB-to-serial cable, power on the machine, and press the INTERRUPT button. Then, from a terminal on the PC, run

`ser09.py run myprogram.s19`

(`.s19` files are the Motorola equivalent of Intel HEX files, a text representation of the binary executable.) The status LED should blink yellow. If the program does not run after ser09 prints "All OK," you can issue the command

`ser09.py run`

Depending on your system, this might happen often. If that's the case, use this command instead:

`ser09.py load myprogram.s19 && ser09.py run`

Programs
--------

### asteroids
Nearly-complete Asteroids clone. The most complex Ultim809 program.

### date
Get and set the date/time from the DS1307 real time clock.

### kbdtest
Tests the PS/2 keyboard routines.

### life
Conway's Game of Life animation with color and generative music.

### padtest
Gamepad/joystick button test.

### plasma
Old-school rainbow plasma effect.

### vidtest
Basic test of the video chip.

### weather
Downloads and displays weather information using `httpserial.py` running on a host PC.

Include files
-------------
Supplemental routines, not included in the ROM, are provided in the `include/` directory.

### ds1307.asm
Routines to get and set the date and time from the DS1307.

### httpser.asm
Routines to communicate with `httpserial.py`.

### i2c.asm
Bit-banged I2C routines using the 6522A VIA.

### numio.asm
Routines to print numbers in decimal and convert strings to integers.

### random.asm
Simple LFSR-based pseudorandom number generator.

### readline.asm
Routine to read a line of input from the keyboard or serial port.

### ym2149.asm
Routines to interact with the YM2149 sound chip and read the game controllers.