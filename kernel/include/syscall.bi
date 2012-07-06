#include once "cpu.bi"

namespace syscall
    enum
        PROCESS_GET_PID = 1
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
    
    declare sub handler (cpu as cpu_state ptr)
end namespace
