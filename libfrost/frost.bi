#pragma once

declare function frost_syscall_process_get_pid () as uinteger
declare function frost_syscall_get_parent_pid () as uinteger

declare function frost_syscall_thread_get_tid () as uinteger
declare function frost_syscall_thread_create (entry as any ptr, stackaddr as any ptr) as integer
declare sub frost_syscall_thread_sleep (ms as uinteger)
declare sub frost_syscall_thread_exit ()

declare function frost_syscall_memory_allocate_physical (bytes as uinteger, addr as any ptr) as any ptr

declare sub frost_syscall_port_request (port as uinteger)
declare sub frost_syscall_port_release (port as uinteger)

declare sub frost_syscall_irq_handler_register (irq as uinteger, function_pointer as any ptr)
declare sub frost_syscall_irq_handler_exit (irq as uinteger)

declare sub frost_syscall_ipc_handler_call (pid as uinteger)
declare sub frost_syscall_ipc_handler_set (handler as any ptr)
declare sub frost_syscall_ipc_handler_exit ()

declare sub frost_syscall_43 (str_ptr as byte ptr)
