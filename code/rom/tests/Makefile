TESTS = romtest1.s19 romtest2.s19 romtest3.s19
AS = as6809
LD = aslink

all: $(TESTS)

%.s19:%.asm
	$(AS) -lop $<
	$(LD) -ns $@ $(<:.asm=.rel)

clean:
	rm -f *.lst *.rel *.s19
