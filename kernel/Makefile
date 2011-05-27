SRCS = $(shell find src -name *.bas)
SRCS += $(shell find src -name *.asm)
OBJS = $(addsuffix .o,$(basename $(notdir $(SRCS))))

COMPILER = fbc
ASSEMBLER = nasm
LINKER = ld

CFLAGS = -c -nodeflibs -arch 486
AFLAGS = -f elf32
LFLAGS = -melf_i386 -Tkernel.ld

frost.krn: $(OBJS)
	$(LINKER) $(LFLAGS) -o $@ $^

%.o: src/%.bas
	$(COMPILER) $(CFLAGS) $^ -o $@

%.o: src/%.asm
	$(ASSEMBLER) $(AFLAGS) $^ -o $@

clean:
	rm $(OBJS) frost.krn

.PHONY: clean
