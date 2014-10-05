#include "../../kernel/include/syscall_defs.bi"

sub frost_syscall_port_request (port as uinteger)
	asm
		mov eax, SYSCALL_PORT_REQUEST
		mov ebx, [port]
		int &hFF
	end asm
end sub

sub frost_syscall_port_release (port as uinteger)
	asm
		mov eax, SYSCALL_PORT_RELEASE
		mov ebx, [port]
		int &hFF
	end asm
end sub
