#include once "cpu.bi"
#include once "elf32.bi"
#include once "multiboot.bi"

namespace tasks
    
    const MAX_TICKS as uinteger = 50
    
    type task_type
        pid as uinteger
        cpu as any ptr
        page_directory as uinteger ptr
        
        '' important to get a tree-like structure
        parent as task_type ptr
        
        '' RPC
        rpc_handler as any ptr
        
        '' scheduling infos
        ticks_left as uinteger
        ticks_max as uinteger
        
        '' important to get a useful port-management
        io_bitmap as uinteger ptr
        
        '' needed for the linked-list
        next_entry as task_type ptr
    end type
    
    declare function generate_pid () as uinteger
    declare function init_task (entry as any ptr) as task_type ptr
    declare function schedule (cpu as cpu_state ptr) as cpu_state ptr
    declare function get_current_task () as task_type ptr
    declare function check_elf_header (header as elf32.Elf32_Ehdr ptr) as integer
    declare sub init_elf (image as any ptr)
    declare sub create_tasks_from_mb (mbinfo as multiboot_info ptr)
end namespace