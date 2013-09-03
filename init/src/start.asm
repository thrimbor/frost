extern fb_ctor__init
global _start

section .text
_start:
	mov esp, stack
	call fb_ctor__init
	jmp $

section .bss
    resb 4096
stack:
