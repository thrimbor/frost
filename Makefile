SRCS = $(shell find src -name *.bas)
OBJS = $(addsuffix .o,$(basename $(notdir $(SRCS))))

CC = fbc
LD = ld

CFLAGS = -c
LDFLAGS = -melf_i386 -Tkernel.ld

frost.krn: $(OBJS)
	$(LD) $(LDFLAGS) -o $@ $^

%.o: src/%.bas
	$(CC) $(CFLAGS) $^ -o $@

clean:
	rm $(OBJS)
	rm frost.krn

.PHONY: clean
