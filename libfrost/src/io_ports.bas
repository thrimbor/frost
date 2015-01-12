#include "../../kernel/include/syscall_defs.bi"
#include "libfrost_internal.bi"

sub frost_syscall_port_request (port as uinteger)
	syscall_param1(SYSCALL_PORT_REQUEST, port)
end sub

sub frost_syscall_port_release (port as uinteger)
	syscall_param1(SYSCALL_PORT_RELEASE, port)
end sub
