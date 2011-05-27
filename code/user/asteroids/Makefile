# Makefile for Ultim809 user programs
# Code must start at address 0x0100
# The SRecord package is required to build the executable:
#   http://srecord.sourceforge.net
# User programs can also be combined with the ROM and run in the simulator

OUT = asteroids
ASM = $(OUT).asm
OBJ = $(ASM:.asm=.rel)
SREC = $(OUT).s19
BIN = $(OUT).ex9

SIM = ~/Code/mess/mess -inipath /Users/matt

AS = as6809
LD = aslink
SREC_CAT = srec_cat
ORG = 0x0100

all: $(SREC)

.SUFFIXES: .asm .rel

.asm.rel:
	$(AS) -lswop $<

$(SREC): $(OBJ)
	$(LD) -ns $(SREC) $(OBJ)
	$(SREC_CAT) $(SREC) -offset -$(ORG) -o $(BIN) -binary

run: $(SREC)
	$(SIM) ultim809 -cart $(BIN)

debug: $(SREC)
	$(SIM) ultim809 -cart $(BIN) -debug

clean:
	rm -f $(SREC) $(BIN) *.lst *.rel *.sym *.map

