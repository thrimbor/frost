#include once "kernel.bi"
#include once "syscall.bi"
#include once "tasks.bi"
#include once "video.bi"

namespace syscall
    
    sub handler (cpu as cpu_state ptr)
        dim task as tasks.task_type ptr = tasks.get_current_task()
        
        select case (cpu->eax)
            case syscall.PROCESS_GET_PID
                cpu->ebx = task->pid
            case syscall.PROCESS_GET_PARENT_PID
                if (not(caddr(task->parent) = 0)) then
                    cpu->ebx = task->parent->pid
                else
                    cpu->ebx = 0
                end if
            case syscall.FORTY_TWO
                video.fout("The answer to life, the universe and everything is... 42\n")
        end select
    end sub
    
end namespace
