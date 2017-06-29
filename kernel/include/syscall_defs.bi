#pragma once

enum syscalls
	SYSCALL_KERNEL_REQUEST_FAST_SYSCALL_INTERFACE

	SYSCALL_PROCESS_GET_PID
	SYSCALL_PROCESS_GET_PARENT_PID
	SYSCALL_PROCESS_CREATE
	SYSCALL_PROCESS_EXIT
	SYSCALL_PROCESS_KILL

	SYSCALL_THREAD_GET_TID
	SYSCALL_THREAD_CREATE
	SYSCALL_THREAD_SLEEP
	SYSCALL_THREAD_YIELD
	SYSCALL_THREAD_EXIT

	SYSCALL_MEMORY_ALLOCATE_PHYSICAL

	SYSCALL_PORT_REQUEST
	SYSCALL_PORT_RELEASE

	SYSCALL_IRQ_HANDLER_REGISTER
	SYSCALL_IRQ_HANDLER_EXIT

	SYSCALL_IPC_HANDLER_CALL
	SYSCALL_IPC_HANDLER_SET
	SYSCALL_IPC_HANDLER_EXIT

	SYSCALL_VFS_CREATE_NODE
	SYSCALL_VFS_OPEN
	SYSCALL_VFS_CLOSE
	SYSCALL_VFS_READ
	SYSCALL_VFS_WRITE

	SYSCALL_FORTY_TWO = 42
end enum

type vfs_create_info
    pathname as zstring ptr
    nodename as zstring ptr
    handler as any ptr
    id as integer
end type

type vfs_open_info
    path as zstring ptr '*< the complete path of the node which is to be opened
    flags as uinteger
    handle as uinteger  '*< a caller-defined handle which gets passed to the callback
    callback as any ptr '*< the address of a function that gets called as a callback
end type
