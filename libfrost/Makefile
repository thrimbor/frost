SRCS = $(shell find src -name *.bas)
OBJS = $(addprefix obj/, $(addsuffix .o,$(basename $(notdir $(SRCS)))))

COMPILER = fbc
AR = ar

CFLAGS = -c -nodeflibs -lang fb -arch 486
ARFLAGS = -cvq

libfrost.a: $(OBJS)
	$(AR) $(ARFLAGS) $@ $^

obj/%.o: src/%.bas
	$(COMPILER) $(CFLAGS) $^ -o $@

clean:
	rm $(OBJS) libfrost.a

.PHONY: clean
