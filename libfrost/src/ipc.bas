#include "../../kernel/include/syscall_defs.bi"

sub frost_syscall_ipc_handler_call (pid as uinteger)
	asm
		mov eax, SYSCALL_IPC_HANDLER_CALL
		mov ebx, [pid]
		int &hFF
	end asm
end sub

sub frost_syscall_ipc_handler_set (handler as any ptr)
	asm
		mov eax, SYSCALL_IPC_HANDLER_SET
		mov ebx, [handler]
		int &hFF
	end asm
end sub

sub frost_syscall_ipc_handler_exit ()
	asm
		mov eax, SYSCALL_IPC_HANDLER_EXIT
		int &hFF
	end asm
end sub
