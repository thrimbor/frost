#pragma once

#include "isf.bi"

namespace syscall
    enum syscalls
        KERNEL_REQUEST_FAST_SYSCALL_INTERFACE
        
        PROCESS_GET_PID
        PROCESS_GET_PARENT_PID
        PROCESS_CREATE
        PROCESS_SUICIDE
        PROCESS_KILL
        PROCESS_SLEEP
        PROCESS_REQUEST_PORT
        PROCESS_FREE_PORT
        
        RPC_SET_HANDLER
        RPC_CALL
        RPC_WAIT_FOR_CALL
        
        FORTY_TWO = 42
    end enum
    
    declare sub handler (isf as interrupt_stack_frame ptr)
end namespace
