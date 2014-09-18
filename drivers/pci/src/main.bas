#include "../../../kernel/include/syscall_defs.bi"

declare sub outl (port as ushort, value as uinteger<32>)

const CONFIG_ADDRESS = &hCF8
const CONFIG_DATA = &hCFC

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
	mov ebx, CONFIG_ADDRESS
	int &h62
	mov eax, syscalls.SYSCALL_PORT_REQUEST
	mov ebx, CONFIG_DATA
	int &h62
end asm


asm jmp $


sub outl (port as ushort, value as uinteger<32>)
    asm
        movw dx, [port]
        mov eax, [value]
        out dx, eax
    end asm
end sub

'function inpl (port as ushort) as uinteger<32>
    'asm
        'mov dx, [port]
        'inl eax, dx
        'mov [function], eax
    'end asm
'end function
