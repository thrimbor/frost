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
    
    function generate_pid () as uinteger
        static next_pid as uinteger = 0
        next_pid += 1
        return next_pid-1
    end function
    
    sub init_task (entry as any ptr)
        dim kernelstack as any ptr = pmm.alloc()
        dim userstack as any ptr = pmm.alloc()
        dim task as task_type ptr = pmm.alloc()
        dim cpu as cpu_state ptr = (kernelstack+4096-sizeof(cpu_state))
        
        cpu->eax = 0
        cpu->ebx = 0
        cpu->ecx = 0
        cpu->edx = 0
        cpu->esi = 0
        cpu->edi = 0
        cpu->ebp = 0
        cpu->eip = cuint(entry)
        cpu->esp = cuint(userstack)+4096
        cpu->cs = &h18 or &h03
        cpu->ss = &h20 or &h03
        cpu->eflags = &h200
        
        task->cpu = cpu
        
        '// give the task a pid
        task->pid = generate_pid()
        
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