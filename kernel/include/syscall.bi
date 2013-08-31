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

namespace syscall
    enum syscalls
        KERNEL_REQUEST_FAST_SYSCALL_INTERFACE
        
        PROCESS_GET_PID
        PROCESS_GET_PARENT_PID
        PROCESS_CREATE
        PROCESS_EXIT
        PROCESS_KILL
        
        THREAD_GET_TID
        THREAD_CREATE
        THREAD_SLEEP
        THREAD_EXIT
        
        PORT_REQUEST
        PORT_RELEASE
        
        SET_INTERRUPT_HANDLER
        
        RPC_SET_HANDLER
        RPC_CALL
        RPC_WAIT_FOR_CALL
        
        FORTY_TWO = 42
    end enum
    
    declare function handler (param1 as uinteger, param2 as uinteger, param3 as uinteger, param4 as uinteger) as uinteger
end namespace
