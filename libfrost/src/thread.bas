#include "../../kernel/include/syscall_defs.bi"
#include "libfrost_internal.bi"

function frost_syscall_thread_get_tid () as uinteger
	syscall_param0_ret(SYSCALL_THREAD_GET_TID, function)
end function

function frost_syscall_thread_create (entry as any ptr, stackaddr as any ptr) as integer
	syscall_param2_ret(SYSCALL_THREAD_CREATE, function, entry, stackaddr)
end function

sub frost_syscall_thread_sleep (ms as uinteger)
	syscall_param1(SYSCALL_THREAD_SLEEP, ms)
end sub

sub frost_syscall_thread_exit ()
	syscall_param0(SYSCALL_THREAD_EXIT)
end sub
