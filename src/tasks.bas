#include once "inc/tasks.bi"
#include once "inc/cpu.bi"
#include once "inc/video.bi"

namespace tasks
    dim shared stack_a (0 to 4095) as ubyte
    dim shared stack_b (0 to 4095) as ubyte
    dim shared task_states (0 to 1) as cpu_state ptr
    dim shared current_task as integer = -1
    dim shared num_tasks as integer = 2
    
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
    
    function init_task (stack as any ptr, entry as any ptr) as cpu_state ptr
        dim cpustate as cpu_state ptr = stack
        
        cpustate->eax = 0
        cpustate->ebx = 0
        cpustate->ecx = 0
        cpustate->edx = 0
        cpustate->esi = 0
        cpustate->edi = 0
        cpustate->ebp = 0
        cpustate->eip = cuint(entry)
        cpustate->cs = &h08
        cpustate->eflags = &h202
        
        return cpustate
    end function
    
    sub init_multitasking()
        task_states(0) = init_task(@stack_a(0), @task_a)
        task_states(1) = init_task(@stack_b(0), @task_b)
    end sub
    
    function schedule (cpu as cpu_state ptr) as cpu_state ptr
        if (current_task >= 0) then task_states(current_task) = cpu
        
        current_task += 1
        current_task mod= num_tasks
        
        return task_states(current_task)
    end function
end namespace