SRCS = $(shell find src -name *.bas)
SRCS += $(shell find src -name *.asm)
OBJS = $(addprefix obj/, $(addsuffix .o,$(basename $(notdir $(SRCS)))))

COMPILER = fbc
ASSEMBLER = nasm
LINKER = ld

CFLAGS = -c -nodeflibs -lang fb -arch 486 -i ./include/ -g -d FROST_DEBUG
AFLAGS = -f elf32
LFLAGS = -melf_i386 -Tkernel.ld

frost.krn: $(OBJS)
	$(LINKER) $(LFLAGS) -o $@ $^

obj/%.o: src/%.bas
	$(COMPILER) $(CFLAGS) $^ -o $@

obj/%.o: src/arch/x86/%.bas
	$(COMPILER) $(CFLAGS) $^ -o $@

obj/%.o: src/%.asm
	$(ASSEMBLER) $(AFLAGS) $^ -o $@

obj/%.o: src/arch/x86/%.asm
	$(ASSEMBLER) $(AFLAGS) $^ -o $@

clean:
	rm $(OBJS) frost.krn

.PHONY: clean
