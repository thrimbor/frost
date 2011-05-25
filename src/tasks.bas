#include once "inc/tasks.bi"
#include once "inc/pmm.bi"
#include once "inc/cpu.bi"
#include once "inc/video.bi"

namespace tasks
    sub task_a ()
        do
            video.cout("A")
        loop
    end sub
    
    sub task_b ()
        do
            video.cout("B")
        loop
    end sub
    
    dim shared first_task as task_type ptr = 0
    dim shared current_task as task_type ptr = 0
    
    sub init_task (entry as any ptr)
        dim stack as any ptr = pmm.alloc()
        dim task as task_type ptr = pmm.alloc()
        dim cpu as cpu_state ptr = stack
        
        cpu->eax = 0
        cpu->ebx = 0
        cpu->ecx = 0
        cpu->edx = 0
        cpu->esi = 0
        cpu->edi = 0
        cpu->ebp = 0
        cpu->eip = cuint(entry)
        cpu->cs = &h08
        cpu->eflags = &h202
        
        task->cpu = cpu
        
        task->next_entry = first_task
        first_task = task
    end sub
    
    sub init_multitasking ()
        init_task(@task_b)
        init_task(@task_a)
    end sub
    
    function schedule (cpu as cpu_state ptr) as cpu_state ptr
        if (not(current_task = 0)) then current_task->cpu = cpu
        
        if (current_task = 0) then
            current_task = first_task
        else
            current_task = current_task->next_entry
            if (current_task = 0) then current_task = first_task
        end if
        
        return current_task->cpu
    end function
end namespace