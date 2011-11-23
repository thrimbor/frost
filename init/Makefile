SRCS = $(shell find src -name *.bas)
OBJS = $(addprefix obj/, $(addsuffix .o,$(basename $(notdir $(SRCS)))))

COMPILER = fbc
LINKER = ld

CFLAGS = -c -nodeflibs -lang fb -arch 486
LFLAGS = -melf_i386 -Ttext=0xA00000

init.elf: $(OBJS)
	$(LINKER) $(LFLAGS) -o $@ $^

obj/%.o: src/%.bas
	$(COMPILER) $(CFLAGS) $^ -o $@

clean:
	rm $(OBJS) init.elf

.PHONY: clean
