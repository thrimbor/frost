#include once "inc/int_stubs.bi"
#include once "inc/pic.bi"
#include once "inc/video.bi"

sub handle_interrupt cdecl (cpu as cpu_state ptr)
    if (cpu->int_nr = &h30) then
        video.cout("The syscall-interrupt has been called.")
    end if
    
    '// important: if the int is an irq, send the EOI
    if ((cpu->int_nr >= &h20) and (cpu->int_nr <= &h2F)) then
        pic.send_eoi(cpu->int_nr - &h20)
    end if
end sub
