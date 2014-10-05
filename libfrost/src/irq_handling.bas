#include "../../kernel/include/syscall_defs.bi"

sub frost_syscall_irq_handler_set (function_pointer as any ptr)
	asm
		mov eax, SYSCALL_IRQ_HANDLER_SET
		mov ebx, [function_pointer]
		int &hFF
	end asm
end sub

sub frost_syscall_irq_handler_register (irq as uinteger)
	asm
		mov eax, SYSCALL_IRQ_HANDLER_REGISTER
		mov ebx, 1
		int &hFF
	end asm
end sub

sub frost_syscall_irq_handler_exit (irq as uinteger)
	asm
		mov eax, SYSCALL_IRQ_HANDLER_EXIT
		mov ebx, [irq]
		int &hFF
	end asm
end sub
