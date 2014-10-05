extern MAIN
global _start

section .text
_start:
	call MAIN
	jmp $
