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
#include "kmm.bi"

type irq_handler_type
	process as process_type ptr
	handler as any ptr
	
	list as list_head
	
	declare operator new (size as uinteger) as any ptr
	declare operator new[] (size as uinteger) as any ptr
	declare operator delete (buffer as any ptr)
	
	declare constructor (process as process_type ptr, handler as any ptr)
end type

operator irq_handler_type.new (size as uinteger) as any ptr
	return kmalloc(size)
	'' constructor is called automatically
end operator

operator irq_handler_type.delete (buffer as any ptr)
	kfree(buffer)
	'' destructor is called automatically
end operator

constructor irq_handler_type (process as process_type ptr, handler as any ptr)
	this.process = process
	this.handler = handler
end constructor

dim shared irq_handlers(0 to 15) as list_head

function register_irq_handler (process as process_type ptr, irq as integer, handler_address as any ptr) as boolean
	if ((irq < lbound(irq_handlers,1)) or (irq > ubound(irq_handlers,1))) then return false
	
	dim h as irq_handler_type ptr = new irq_handler_type(process, handler_address)
	irq_handlers(irq).insert_after(@h->list)
	
	pic_unmask(irq)
	return true
end function

'' this is the common interrupt handler which gets called for every interrupt.
function handle_interrupt cdecl (isf as interrupt_stack_frame ptr) as interrupt_stack_frame ptr
    dim reschedule as uinteger = false
    
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
				
				return isf
			end if
			
			'' mask the IRQ to prevent it from firing again (gets unmasked when the thread is done)
			'' FIXME: maybe we should only mask when a thread could be created?
			pic_mask(isf->int_nr - &h20)
		
			'' IRQ
			list_foreach(h, irq_handlers(isf->int_nr-&h20))
				dim x as irq_handler_type ptr = LIST_GET_ENTRY(h, irq_handler_type, list)
				dim thread as thread_type ptr = spawn_popup_thread(x->process, x->handler)
				
				dim m as uinteger ptr = vmm_kernel_automap(thread->userstack_p, PAGE_SIZE)
				m[PAGE_SIZE\4-1] = isf->int_nr-&h20
				m[PAGE_SIZE\4-2] = 0  '' return address, needed because of cdecl!
				vmm_kernel_unmap(x, PAGE_SIZE)
				thread->isf->esp -= 8
			list_next(h)
		
        case &h20                                           '' timer IRQ
			reschedule = true
			
        case &hFF                                          '' syscall interrupt
            isf->eax = syscall_handler(isf->eax, isf->ebx, isf->ecx, isf->edx)
            
        case else
            
    end select
    
    if (get_current_thread() <> nullptr) then
		if (get_current_thread()->flags and THREAD_FLAG_RESCHEDULE) then
			reschedule = true
			get_current_thread()->flags and= not THREAD_FLAG_RESCHEDULE
		end if
	end if
	
	if (reschedule) then
		thread_switch(isf)
	end if
    
    '' important: if the int is an IRQ, send the EOI
    if (apic_enabled) then
		lapic_eoi()
	else
		if ((isf->int_nr > &h1F) and (isf->int_nr < &h30)) then
			pic_send_eoi(isf->int_nr - &h20)
		end if
	end if
    
    return get_current_thread()->isf
end function
