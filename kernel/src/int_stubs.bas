#include once "kernel.bi"
#include once "int_stubs.bi"
#include once "cpu.bi"
#include once "pic.bi"
#include once "tasks.bi"
#include once "syscall.bi"
#include once "panic.bi"
#include once "video.bi"

'' this is the common interrupt handler which gets called for every interrupt.
function handle_interrupt cdecl (cpu as cpu_state ptr) as cpu_state ptr
    dim new_cpu as cpu_state ptr = cpu
    select case cpu->int_nr
        case 0 to &h13                                     '' check for an exception
            panic.show(1, cpu)
        case &h20                                          '' timer IRQ, so we switch tasks
            new_cpu = tasks.schedule(cpu)
            tss_ptr[1] = cuint(new_cpu)+sizeof(cpu_state)
        case &h62                                          '' syscall, so we call the syscall-handler
            syscall.handler(cpu)
        case else
    end select
    
    '' important: if the int is an IRQ, send the EOI
    if ((cpu->int_nr > &h1F) and (cpu->int_nr < &h30)) then
        pic.send_eoi(cpu->int_nr - &h20)
    end if
    
    '' enable this if paging is ready to swicht page-directories
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
