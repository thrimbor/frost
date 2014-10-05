#include "../../kernel/include/syscall_defs.bi"

function frost_syscall_process_get_pid () as uinteger
	asm
		mov eax, SYSCALL_PROCESS_GET_PID
		int &hFF
		mov [function], eax
	end asm
end function

function frost_syscall_get_parent_pid () as uinteger
	asm
		mov eax, SYCSALL_PROCESS_GET_PARENT_PID
		int &hFF
		mov [function], eax
	end asm
end function


