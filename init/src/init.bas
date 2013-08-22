asm
    .global fb_ctor__init
end asm

dim x as byte ptr = strptr("this is a test")
asm
	mov eax, 43
	mov ebx, [x]
	int &h62
	jmp $
end asm
