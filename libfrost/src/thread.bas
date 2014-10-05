#include "../../kernel/include/syscall_defs.bi"

function frost_syscall_thread_get_tid () as uinteger
	asm
		mov eax, SYSCALL_THREAD_GET_TID
		int &hFF
		mov [function], eax
	end asm
end function

function frost_syscall_thread_create (entry as any ptr, stackaddr as any ptr) as integer
	asm
		mov eax, SYSCALL_THREAD_CREATE
		mov ebx, [entry]
		mov ecx, [stackaddr]
		int &hFF
		mov [function], eax
	end asm
end function

sub frost_syscall_thread_sleep (ms as uinteger)
	asm
		mov eax, SYSCALL_THREAD_SLEEP
		mov ebx, [ms]
		int &hFF
	end asm
end sub

sub frost_syscall_thread_exit ()
	asm
		mov eax, SYSCALL_THREAD_EXIT
		int &hFF
	end asm
end sub
