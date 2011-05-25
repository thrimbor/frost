#include once "cpu.bi"

namespace tasks
    type task_type
        pid as uinteger
        cpu as any ptr
        next_entry as task_type ptr
    end type
    
    declare sub init_task (entry as any ptr)
    declare sub init_multitasking()
    declare function schedule (cpu as cpu_state ptr) as cpu_state ptr
end namespace