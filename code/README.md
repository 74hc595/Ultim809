Ultim809 Code
=============

This directory contains all assembly source code for the Ultim809 ROM and various application programs. Additional scripts to aid development are also included.

All code is written for the open-source ASxxxx cross assembler by Alan R. Baldwin, available online at [http://shop-pdp.kent.edu/ashtml/asxxxx.htm](http://shop-pdp.kent.edu/ashtml/asxxxx.htm). The SRecord suite is also required to create executable files. It's in many package repositories (including Ubuntu and MacPorts) and can also be downloaded from [http://srecord.sourceforge.net/](http://srecord.sourceforge.net/).


Directory structure
-------------------

`rom/` contains the ROM source, and various scripts to generate header files and checksums.

`user/` contains the source of various application programs, and a directory of common include files.

`ser09.py` is a script used to send programs to Ultim809 over a USB-to-serial cable. It can be used to download user programs, as well as update the ROM. See the file for usage details.

`gfx2inc.py` slices an image file into 8x8 or 16x16 tiles and converts them to hexadecimal `.fcb` directives, suitable for including in an assembly program.

`text2inc.py` converts a text file (any file, actually) to hexadecimal `.fcb` directives, suitable for including in an assembly program.

`ym2149.py` includes functions for converting frequencies in hertz to register values for the YM2149 sound chip, and vice versa.

`httpserial.py` is a script that acts as a serial-to-HTTP bridge, allowing Ultim809 to request the contents of URLs over the serial port.

`as6809.vim` is a syntax highlighting file for Vim.

Current features
----------------
Currently, Ultim809 has no mass storage and no interactive monitor. (The prototype did, and I'll be bringing these features over soon.) Programs must be loaded over the serial port using the following procedure:

1.  Make sure a USB-to-serial cable is connected to your PC.
2.  Make sure Ultim809 is on and running (HALT/RUN switch set to RUN).
3.  Press the INTERRUPT button. "Remote ready." should be displayed.
4.  On the PC, run `ser09.py run myprogram.s19`
5.  The status LED should blink yellow and the program should start when the transfer is complete. If not, run `ser09.py run`

The serial device can be changed with the `$SER09_PORT` environment variable. See the script for more details. The ser09 protocol is subject to change in future versions of the ROM.

Code has been written to do the following:

*  write to and read from the serial port
*  display numbers in hex and decimal
*  convert hex and decimal strings to 8- and 16-bit integers
*  generate random numbers with a simple linear feedback shift register
*  interface with the TMS9918A video chip and the YM2149 sound chip
*  read Atari joysticks and Sega 3-button gamepads
*  read the PS/2 keyboard using the 6522A, with a 16 byte scancode buffer
*  convert keyboard scancodes to ASCII characters
*  interface with I2C devices using the 6522
*  get data from the DS1307 real-time clock and set the time
*  download HTTP data from the httpserial.py script running on a PC

The following features of the board are not yet supported, but will be:

*  SPI using the 6522 shift register
*  reading and writing to SD cards
*  FAT16 filesystem operations
*  interactive monitor/command line


Emulation
---------
A somewhat-complete Ultim809 plugin for the MESS emulator is also available from my GitHub. It supports graphics, video, and gamepads, but the keyboard is not emulated.

Writing your own programs
-------------------------
See the `DEVELOPING.md` file in the `code/` directory to learn how to write your own assembly language programs. Note that future revisions of the ROM might require your programs to be reassembled.