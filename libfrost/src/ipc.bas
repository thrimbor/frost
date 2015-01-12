#include "../../kernel/include/syscall_defs.bi"
#include "libfrost_internal.bi"

sub frost_syscall_ipc_handler_call (pid as uinteger)
	syscall_param1(SYSCALL_IPC_HANDLER_CALL, pid)
end sub

sub frost_syscall_ipc_handler_set (handler as any ptr)
	syscall_param1(SYSCALL_IPC_HANDLER_SET, handler)
end sub

sub frost_syscall_ipc_handler_exit ()
	syscall_param0(SYSCALL_IPC_HANDLER_EXIT)
end sub
