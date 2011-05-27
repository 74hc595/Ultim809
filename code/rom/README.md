Ultim809 ROM
============

A Makefile is included to build the ROM on a Unix-like machine with the ASxxxx assembler.

The following scripts are run by the Makefile:

`map2inc` takes the `rom.map` file as an input and generates a `rom0x.inc` header file, that defines the addresses of all global ROM subroutines. (those whose labels are suffixed with a double colon `::`) This file should be included by all user programs.

`gensums` computes the CRC32 and SHA1 hashes of the ROM binary and outputs the results in `checksum.h`. This file is used by the Ultim809 emulator for MESS.

Tests
-----
Simple test programs are provided in the `tests/` directory. They can be used to test basic system functionality before installing the full ROM.

Modifying the ROM
-----------------
Currently, all ROM routines are called by absolute address. If the ROM is modified, all user programs will have to be reassembled to reference the routines' new addresses, or they will crash. This is done for high performance, but may change in the future to improve portability.

ASlink apparently supports separate assembly, but in a very strange way that makes debugging difficult. The quick solution was to include all subroutine `.asm` files from `main.asm`. This means that a `make clean all` is required after modifying a file other than `main.asm`.

`remote.asm` contains the code to receive programs and ROM upgrades from `ser09`. Currently it only supports programming AT28C64B EEPROMs, 64 bytes at a time.

Uploading the ROM
-----------------
To bootstrap the system, you can use my ROMBurner Arduino sketch to burn the `rom.s19` file to an EEPROM chip with ser09:

`ser09.py load rom.s19`

Additionally, ser09 can be used to program the ROM directly on the board. In this case, power on the system, press the INTERRUPT button, turn the EEPROM PROTECT switch to OFF, and then run the command above. If all is OK, turn the EEPROM PROTECT switch back to ON and press the RESET button.