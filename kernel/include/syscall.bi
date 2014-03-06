/'
 ' FROST x86 microkernel
 ' Copyright (C) 2010-2013  Stefan Schmidt
 ' 
 ' This program is free software: you can redistribute it and/or modify
 ' it under the terms of the GNU General Public License as published by
 ' the Free Software Foundation, either version 3 of the License, or
 ' (at your option) any later version.
 ' 
 ' This program is distributed in the hope that it will be useful,
 ' but WITHOUT ANY WARRANTY; without even the implied warranty of
 ' MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 ' GNU General Public License for more details.
 ' 
 ' You should have received a copy of the GNU General Public License
 ' along with this program.  If not, see <http://www.gnu.org/licenses/>.
 '/

#pragma once

#include "isf.bi"

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
	SYSCALL_THREAD_EXIT
	
	SYSCALL_PORT_REQUEST
	SYSCALL_PORT_RELEASE
	
	SYSCALL_SET_INTERRUPT_HANDLER
	
	SYSCALL_RPC_SET_HANDLER
	SYSCALL_RPC_CALL
	SYSCALL_RPC_WAIT_FOR_CALL
	
	SYSCALL_FORTY_TWO = 42
end enum

declare function syscall_handler (param1 as uinteger, param2 as uinteger, param3 as uinteger, param4 as uinteger) as uinteger
