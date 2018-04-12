SRCS = $(shell find src -name *.bas)
SRCS += $(shell find src -name *.asm)
OBJS = $(addprefix obj/, $(addsuffix .o,$(basename $(notdir $(SRCS)))))

COMPILER = fbc
ASSEMBLER = nasm
LINKER = ld

CFLAGS = -c -nodeflibs -lang fb -arch 486
AFLAGS = -f elf32
LFLAGS = -melf_i386 -Tinit.ld

init.elf: $(OBJS)
	$(LINKER) $(LFLAGS) -o $@ $^ ../libfrost/libfrost.a

obj/%.o: src/%.bas
	$(COMPILER) $(CFLAGS) $^ -o $@

obj/%.o: src/%.asm
	$(ASSEMBLER) $(AFLAGS) $^ -o $@

clean:
	rm -f $(OBJS) init.elf

.PHONY: clean
