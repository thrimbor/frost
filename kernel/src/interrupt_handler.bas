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
#include "pmm.bi"

dim shared irq_handlers(0 to 15, 0 to 4) as process_type ptr

function register_irq_handler (process as process_type ptr, irq as integer) as boolean
	if ((irq < lbound(irq_handlers,1)) or (irq > ubound(irq_handlers,1))) then return false
	
	for counter as integer = lbound(irq_handlers,2) to ubound(irq_handlers,2)
		if (irq_handlers(irq, counter) = nullptr) then
			irq_handlers(irq, counter) = process
			return true
		end if
	next
	
	return false
end function

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
		
		case &h21 to &h2F
			'' spurious IRQ?
			if (pic_is_spurious(isf->int_nr)) then
				'' did it come from the slave PIC? then send eoi to the master
				if (isf->int_nr = 15) then pic_send_eoi(&h01)
				
				return new_isf
			end if
			
			'' mask the IRQ to prevent it from firing again (gets unmasked when the thread is done)
			pic_mask(isf->int_nr - &h20)
		
			'' IRQ
			for counter as integer = lbound(irq_handlers,2) to ubound(irq_handlers,2)
				dim process as process_type ptr = irq_handlers(isf->int_nr-&h20, counter)
				if (process <> nullptr) then
					if (process->interrupt_handler <> nullptr) then
						dim thread as thread_type ptr = spawn_popup_thread(process, process->interrupt_handler)
						
						dim x as uinteger ptr = vmm_kernel_automap(thread->userstack_p, PAGE_SIZE)
						x[PAGE_SIZE\4-1] = isf->int_nr-&h20
						x[PAGE_SIZE\4-2] = 0  '' return address, needed because of cdecl!
						vmm_kernel_unmap(x, PAGE_SIZE)
						thread->isf->esp -= 8
					end if
				end if
			next
		
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
            
        case &hFF                                          '' syscall interrupt
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

function irq_is_handler (process as process_type ptr, irq as uinteger) as boolean
	if ((irq < lbound(irq_handlers,1)) or (irq > ubound(irq_handlers,1))) then return false
	
	for counter as integer = lbound(irq_handlers,2) to ubound(irq_handlers,2)
		if (irq_handlers(irq, counter) = process) then
			return true
		end if
	next
	
	return false
end function
