#include once "inc/tasks.bi"
#include once "inc/cpu.bi"
#include once "inc/video.bi"

namespace tasks
    dim shared stack_a (0 to 4095) as ubyte
    dim shared stack_b (0 to 4095) as ubyte
    
    sub task_a ()
        video.cout("A")
    end sub
    
    sub task_b ()
        video.cout("B")
    end sub
    
    sub init_task (stack as any ptr, entry as any ptr)
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
    end sub
end namespace