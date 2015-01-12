#include "../../kernel/include/syscall_defs.bi"
#include "libfrost_internal.bi"

function frost_syscall_memory_allocate_physical (bytes as uinteger, addr as any ptr) as any ptr
	syscall_param2_ret(SYSCALL_MEMORY_ALLOCATE_PHYSICAL, function, bytes, addr)
end function
