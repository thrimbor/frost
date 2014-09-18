extern fb_ctor__main
global _start

section .text
_start:
	mov esp, stack
	call fb_ctor__main
	jmp $

section .bss
    resb 4096
stack:
