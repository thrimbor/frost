#include "../../kernel/include/syscall_defs.bi"

function frost_syscall_memory_allocate_physical (bytes as uinteger, addr as any ptr) as any ptr
	asm
		mov eax, SYSCALL_MEMORY_ALLOCATE_PHYSICAL
		mov ebx, [bytes]
		mov ecx, [addr]
		int &hFF
		mov [function], eax
	end asm
end function
