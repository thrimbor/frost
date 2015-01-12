#include "libfrost_internal.bi"

sub frost_syscall_43 (str_ptr as byte ptr)
	syscall_param1(43, str_ptr)
end sub
