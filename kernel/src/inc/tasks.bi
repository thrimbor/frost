#include once "cpu.bi"

namespace tasks
    type task_type
        pid as uinteger
        cpu as any ptr
        rpc_handler as any ptr
        next_entry as task_type ptr
    end type
    
    declare function generate_pid () as uinteger
    declare sub init_task (entry as any ptr)
    declare sub init_multitasking()
    declare function schedule (cpu as cpu_state ptr) as cpu_state ptr
    declare function get_current_task () as task_type ptr
end namespace