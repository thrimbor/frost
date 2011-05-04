SRCS = $(shell find src -name *.bas)
OBJS = $(addsuffix .o,$(basename $(notdir $(SRCS))))

COMPILER = fbc
LINKER = ld

CFLAGS = -c
LFLAGS = -melf_i386 -Tkernel.ld

frost.krn: $(OBJS)
	$(LINKER) $(LFLAGS) -o $@ $^

%.o: src/%.bas
	$(COMPILER) $(CFLAGS) $^ -o $@

clean:
	rm $(OBJS) frost.krn

.PHONY: clean
