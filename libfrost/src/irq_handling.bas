#include "../../kernel/include/syscall_defs.bi"
#include "libfrost_internal.bi"

sub frost_syscall_irq_handler_register (irq as uinteger, handler as any ptr)
	syscall_param2(SYSCALL_IRQ_HANDLER_REGISTER, irq, handler)
end sub

sub frost_syscall_irq_handler_exit (irq as uinteger)
	syscall_param1(SYSCALL_IRQ_HANDLER_EXIT, irq)
end sub
