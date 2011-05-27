Ultim809 Homebrew 8-Bit Computer
================================

Matt Sarnoff ([http://msarnoff.org/](http://msarnoff.org))

The Ultim809 is a homebrew 8-bit computer built around the Motorola 6809 processor. It's a full-featured home computer with color graphics, sound, and support for game controllers and PS/2 keyboards.

It won two blue ribbons (Editor's Choice awards) at Bay Area Maker Faire 2011!

Full feature list:

*  Motorola 68B09E processor at 2 MHz
*  512KB static RAM (bank-switched, 48KB available at once) expandable to 4MB
*  8KB EEPROM, self-programmable
*  TMS9918A graphics chip and composite video output (256x192 resolution, 15 colors, 32 sprites)
*  YM2149 sound chip (3 channels, square wave/noise, envelope generator)
*  Two ports for 9-pin Atari joysticks or Sega Genesis gamepads
*  Serial interface (16550 UART) with 6-pin FTDI connector
*  PS/2 keyboard support
*  I2C interface and DS1307 real-time clock with backup battery
*  SD card slot (not working yet...)
*  Expansion slot, supports 4 devices without additional decoding circuitry

I am making the schematics, design files, and source code available to anyone interested in learning about the project, or constructing their own. All material is made available under my (very simple) [msarnoff.org license.](http://www.msarnoff.org/LICENSE)

Schematics and PCB layout file are provided for use with the [open-source gEDA suite.](http://gpleda.org) Be aware that board revision 0 has errors: I have provided instructions on correcting them by cutting traces and adding wires.

Ultim809 currently has no working mass storage, so a PC with a Unix-like operating system (Linux, Mac OS X, etc.) and command-line skills are recommended for working with Ultim809. You'll also want a [5 volt FTDI USB-to-serial cable.](http://www.sparkfun.com/products/9718)

No microcontrollers or programmable logic chips are used, so an expensive programmer is not required. The 8K EEPROM can be programmed with a [simple Arduino circuit.](*****)

The 68B09E is still available from Jameco and other electronics retailers, but you'll probably have to buy the TMS9918A and YM2149 from eBay.

Directory structure
-------------------
`circuit/` contains the schematic, bill of materials, and PCB layout files.

`code/` contains the assembly code for the ROM and application programs, as well as tools for writing your own programs.

`code/user/DEVELOPING.md` contains tips for developing Ultim809 applications. It assumes a familiarity with 6809 assembly language.
