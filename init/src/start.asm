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
	call MAIN
	jmp $

