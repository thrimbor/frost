#include once "inc/int_stubs.bi"
#include once "inc/cpu.bi"
#include once "inc/pic.bi"
#include once "inc/tasks.bi"
#include once "inc/syscall.bi"
#include once "inc/panic.bi"
#include once "inc/video.bi"

common shared tss_ptr as uinteger ptr

function handle_interrupt cdecl (cpu as cpu_state ptr) as cpu_state ptr
    dim new_cpu as cpu_state ptr = cpu
    select case cpu->int_nr
        case 0 to &h13
            panic.show(1, cpu)
        case &h20
            new_cpu = tasks.schedule(cpu)
            tss_ptr[1] = cuint(new_cpu)+sizeof(cpu_state)
        case &h62
            dim task as tasks.task_type ptr = tasks.get_current_task()
            select case cpu->eax
                case syscall.get_pid
                    cpu->ebx = task->pid
                case 666
                    video.cout("The syscall-interrupt has been called.",video.endl)
            end select
        case else
    end select
    
    '// important: if the int is an irq, send the EOI
    if ((cpu->int_nr > &h1F) and (cpu->int_nr < &h30)) then
        pic.send_eoi(cpu->int_nr - &h20)
    end if
    /'
    if (not(cpu = new_cpu)) then
        dim pagedir as uinteger ptr = (tasks.get_current_task())->page_directory
        asm
            mov eax, [pagedir]
            mov cr3, eax
        end asm
    end if
    '/
    return new_cpu
end function
