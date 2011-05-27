# Makefile for Ultim809 user programs
# Code must start at address 0x0100
# The SRecord package is required to build the executable:
#   http://srecord.sourceforge.net
# User programs can also be combined with the ROM and run in the simulator

OUT_DATE = date
ASM_DATE = $(OUT_DATE).asm
OBJ_DATE = $(ASM_DATE:.asm=.rel)
SREC_DATE = $(OUT_DATE).s19
BIN_DATE = $(OUT_DATE).ex9

OUT_SETDATE = setdate
ASM_SETDATE = $(OUT_SETDATE).asm
OBJ_SETDATE = $(ASM_SETDATE:.asm=.rel)
SREC_SETDATE = $(OUT_SETDATE).s19
BIN_SETDATE = $(OUT_SETDATE).ex9

OUT = $(OUT_DATE) $(OUT_SETDATE)
OBJ = $(OBJ_DATE) $(OBJ_SETDATE)
SREC = $(SREC_DATE) $(SREC_SETDATE)
BIN = $(BIN_DATE) $(BIN_SETDATE)

SIM = ~/Code/mess/mess -inipath /Users/matt

AS = as6809
LD = aslink
SREC_CAT = srec_cat
ORG = 0x0100

all: $(SREC)

.SUFFIXES: .asm .rel

.asm.rel:
	$(AS) -lswop $<

$(SREC_DATE): $(OBJ_DATE)
	$(LD) -ns $(SREC_DATE) $(OBJ_DATE)
	$(SREC_CAT) $(SREC_DATE) -offset -$(ORG) -o $(BIN_DATE) -binary

$(SREC_SETDATE): $(OBJ_SETDATE)
	$(LD) -ns $(SREC_SETDATE) $(OBJ_SETDATE)
	$(SREC_CAT) $(SREC_SETDATE) -offset -$(ORG) -o $(BIN_SETDATE) -binary

run: $(SREC)
	$(SIM) ultim809 -cart $(BIN)

debug: $(SREC)
	$(SIM) ultim809 -cart $(BIN) -debug

clean:
	rm -f $(SREC) $(BIN) *.lst *.rel *.sym *.map

