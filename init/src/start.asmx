extern fb_ctor__init
global _start

section .text
_start:
	call fb_ctor__init
	
	;; process should suicide here
	jmp $
