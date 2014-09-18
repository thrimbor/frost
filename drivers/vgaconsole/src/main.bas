#include "../../../kernel/include/syscall_defs.bi"

declare sub _fb_Out cdecl alias "fb_Out" (port as ushort, value as ubyte)
declare function _fb_In cdecl alias "fb_In" (port as ushort) as ubyte

asm
    .global fb_ctor__main
end asm

'' request access to the textbuffer
dim buffer as byte ptr

asm
	mov eax, syscalls.SYSCALL_MEMORY_ALLOCATE_PHYSICAL
	mov ebx, 4096
	mov ecx, &hb8000
	int &h62
	mov [buffer], eax
end asm

asm
	mov eax, syscalls.SYSCALL_PORT_REQUEST
	mov ebx, &h3D4
	int &h62
	mov eax, syscalls.SYSCALL_PORT_REQUEST
	mov ebx, &h3D5
	int &h62
end asm

out(&h3D4, 14)
out(&h3D5, &h07)
out(&h3D4, 15)
out(&h3D5, &hD0)

for x as uinteger = 0 to 4000
	buffer[x] = 0
next

dim r as uinteger = 0

dim x as byte ptr = strptr("this is a test from the vgaconsole-driver!")
dim c as uinteger = 0
while (x[c] <> 0)
	buffer[r] = x[c]
	c += 1
	r += 1
	buffer[r] = 7
	r += 1
wend


asm jmp $


sub _fb_Out cdecl alias "fb_Out" (port as ushort, value as ubyte)
    asm
        movw dx, [port]
        movb al, [value]
        outb dx, al
    end asm
end sub

function _fb_In cdecl alias "fb_In" (port as ushort) as ubyte
    asm
        movw dx, [port]
        inb al, dx
        mov [function], al
    end asm
end function
