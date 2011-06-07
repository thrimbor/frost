#include once "cpu.bi"
#include once "multiboot.bi"

namespace tasks
    type task_type
        pid as uinteger
        cpu as any ptr
        page_directory as uinteger ptr
        rpc_handler as any ptr
        next_entry as task_type ptr
    end type
    
    declare function generate_pid () as uinteger
    declare function init_task (entry as any ptr) as task_type ptr
    declare function schedule (cpu as cpu_state ptr) as cpu_state ptr
    declare function get_current_task () as task_type ptr
    declare sub create_tasks_from_mb (mbinfo as multiboot_info ptr)
end namespace