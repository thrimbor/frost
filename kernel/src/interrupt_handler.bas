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
#include "apic.bi"
#include "process.bi"
#include "syscall.bi"
#include "panic.bi"

'' this is the common interrupt handler which gets called for every interrupt.
function handle_interrupt cdecl (isf as interrupt_stack_frame ptr) as interrupt_stack_frame ptr
    dim new_isf as interrupt_stack_frame ptr = isf
    
    select case isf->int_nr
        case 0 to &h0C                                      '' exception
			panic_exception(isf)                      '' show panic screen
        case &h0D
			if (tss_ptr->io_bitmap_offset = TSS_IO_BITMAP_NOT_LOADED) then
				set_io_bitmap()
			else
				panic_exception(isf)
			end if
		case &h0E to &h13
			panic_exception(isf)
        case &h20                                           '' timer IRQ
			dim old_process as process_type ptr = nullptr
			if (get_current_thread() <> nullptr) then
				old_process = get_current_thread()->parent_process
			end if
			
            dim new_thread as thread_type ptr = schedule(isf)  '' select a new thread
            
            '' set his esp0 in the tss
            tss_ptr->esp0 = cuint(new_thread->isf) + sizeof(interrupt_stack_frame)
            
            '' load the new pagedir
            if (new_thread->parent_process <> old_process) then
				vmm_activate_context(@new_thread->parent_process->context)
			end if
			
            '' load the new stack frame
            new_isf = new_thread->isf
            
        case &h62                                          '' syscall interrupt
            isf->eax = syscall_handler(isf->eax, isf->ebx, isf->ecx, isf->edx)
            
        case else
            
    end select
    
    '' important: if the int is an IRQ, send the EOI
    if (apic_enabled) then
		lapic_eoi()
	else
		if ((isf->int_nr > &h1F) and (isf->int_nr < &h30)) then
			pic_send_eoi(isf->int_nr - &h20)
		end if
	end if
    
    return new_isf
end function
