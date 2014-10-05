;extern fb_ctor__init
;global _start

;section .text
;_start:
;	call fb_ctor__init
;	jmp $

extern MAIN
extern THREADFUNC
global _start

section .text
_start:
	;call MAIN
	;mov eax, 666
	;mov ebx, THREADFUNC
	;mov ecx, stack
	;int 0xFF
	call MAIN
	jmp $
	
section .bss
    resb 4096
stack:
