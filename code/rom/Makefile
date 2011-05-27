ASM = main.asm
OBJ = $(ASM:.asm=.rel)
OUT = rom
SREC = $(OUT).s19
BIN = $(OUT).bin
ORG = 0xE000
OUTINC = rom06.inc
CHECKSUMS = checksums.h

AS = as6809
LD = aslink
MAP2INC = ruby map2inc
GENSUMS = python gensums
SERDEVICE = /dev/ttyUSB0

all: $(SREC) $(BIN)

.SUFFIXES: .asm .rel

.asm.rel:
	$(AS) -lop $<

$(SREC): $(OBJ)
	$(LD) -nsmw $(SREC) $(OBJ)
	$(MAP2INC) $(OUT).map $(OUTINC)
	srec_info $(SREC)

$(BIN): $(SREC)
	srec_cat $(SREC) -offset -$(ORG) -o $(BIN) -binary
	$(GENSUMS) $(BIN) > $(CHECKSUMS)

clean:
	rm -f $(SREC) $(BIN) $(OUTINC) $(CHECKSUMS) *.lst *.rel *.sym *.map

ser:
	screen $(SERDEVICE) 38400

