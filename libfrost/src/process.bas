#include "../../kernel/include/syscall_defs.bi"
#include "libfrost_internal.bi"

function frost_syscall_process_get_pid () as uinteger
	syscall_param0_ret(SYSCALL_PROCESS_GET_PID, function)
end function

function frost_syscall_get_parent_pid () as uinteger
	syscall_param0_ret(SYSCALL_PROCESS_GET_PARENT_PID, function)
end function


