#include once "kernel.bi"
#include once "interrupt_handler.bi"
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
        case 0 to &h13                                     '' exception
            panic.show(1, cpu)                             '' show panic screen
            
        case &h20                                          '' timer IRQ
            new_cpu = tasks.schedule(cpu)                  '' switch tasks
            tss_ptr[1] = cuint(new_cpu)+sizeof(cpu_state)
            
        case &h62                                          '' syscall interrupt
            syscall.handler(cpu)                           '' call the syscall-handler
            
        case else
            
    end select
    
    '' important: if the int is an IRQ, send the EOI
    if ((cpu->int_nr > &h1F) and (cpu->int_nr < &h30)) then
        pic.send_eoi(cpu->int_nr - &h20)
    end if
    
    '' enable this if paging is ready to switch page-directories
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
