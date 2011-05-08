#include once "inc/int_stubs.bi"
#include once "inc/video.bi"

sub handle_interrupt (cpu as cpu_state ptr)
    if (cpu->int_nr = &h30) then
        video.cout("The syscall-interrupt has been called.")
    end if
end sub
