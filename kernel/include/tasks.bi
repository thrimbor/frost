#pragma once

#include "cpu.bi"
#include "elf32.bi"
#include "multiboot.bi"

namespace tasks
    
    const MAX_TICKS as uinteger = 50
    
    const STATE_DISABLED = 0
    const STATE_RUNNING = 1
    const STATE_SLEEPING = 2

    type task_type_ as task_type  '' needed because of circular reference
        
    type thread_type
        '' pointer to the owning task
        task as task_type_ ptr
        
        '' id of the thread
        id as uinteger
        
        '' state of the thread
        state as uinteger
        
        '' bottom of the kernel stack
        kernelstack_bottom as any ptr
        
        '' bottom of the usermode stack
        userstack_bottom as any ptr
        
        '' cpu state of the thread (lies inside the kernelstack)
        cpu as cpu_state ptr
        
        '' scheduling infos
        ticks_left as uinteger
        ticks_max as uinteger
        
        '' needed for the linked list
        next_entry as thread_type ptr
    end type
    
    type task_type
        pid as uinteger
        
        vmm_context as uinteger ptr
        
        '' state of the task
        state as uinteger
        
        '' thread list
        threads as thread_type ptr
        
        '' next available thread id
        next_tid as uinteger
        
        '' important to get a tree-like structure
        parent as task_type ptr
        
        '' RPC
        rpc_handler as any ptr
        
        '' important to get a useful port-management
        io_bitmap as uinteger ptr
        
        '' needed for the linked list
        next_entry as task_type ptr
    end type
    
    declare function generate_pid () as uinteger
    declare function init_task (entry as any ptr) as task_type ptr
    declare function schedule (cpu as cpu_state ptr) as cpu_state ptr
    declare function get_current_task () as task_type ptr
    declare sub init_elf (image as any ptr)
    declare sub create_tasks_from_mb (mbinfo as multiboot_info ptr)
end namespace
