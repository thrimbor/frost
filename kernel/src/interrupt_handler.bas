/'
 ' FROST x86 microkernel
 ' Copyright (C) 2010-2013  Stefan Schmidt
 ' 
 ' This program is free software: you can redistribute it and/or modify
 ' it under the terms of the GNU General Public License as published by
 ' the Free Software Foundation, either version 3 of the License, or
 ' (at your option) any later version.
 ' 
 ' This program is distributed in the hope that it will be useful,
 ' but WITHOUT ANY WARRANTY; without even the implied warranty of
 ' MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 ' GNU General Public License for more details.
 ' 
 ' You should have received a copy of the GNU General Public License
 ' along with this program.  If not, see <http://www.gnu.org/licenses/>.
 '/

#include "kernel.bi"
#include "interrupt_handler.bi"
#include "isf.bi"
#include "thread.bi"
#include "pic.bi"
#include "process.bi"
#include "syscall.bi"
#include "panic.bi"
#include "video.bi"

'' this is the common interrupt handler which gets called for every interrupt.
function handle_interrupt cdecl (isf as interrupt_stack_frame ptr) as interrupt_stack_frame ptr
    dim new_isf as interrupt_stack_frame ptr = isf
    'dim old_task as tasks.task_type ptr = tasks.get_current_task()
    
    select case isf->int_nr
        case 0 to &h13                                     '' exception
            panic.panic_exception(isf)                      '' show panic screen
            
            
        case &h20                                          '' timer IRQ
			'' select a new thread
            dim new_thread as thread_type ptr = schedule(isf)
            '' set his esp0 in the tss
            tss_ptr[1] = cuint(new_thread->isf) + sizeof(interrupt_stack_frame)
            '' load the new pagedir
            '' TODO: - only load a new pagedir if the process-id has changed
            vmm.activate_context(@new_thread->parent_process->vmm_context)
            '' load the new stack frame
            new_isf = new_thread->isf
            
        case &h62                                          '' syscall interrupt
            syscall.handler(isf)                           '' call the syscall-handler
            
        case else
            
    end select
    
    '' important: if the int is an IRQ, send the EOI
    if ((isf->int_nr > &h1F) and (isf->int_nr < &h30)) then
        pic.send_eoi(isf->int_nr - &h20)
    end if
    
    return new_isf
end function
