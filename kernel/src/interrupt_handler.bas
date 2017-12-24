/'
 ' FROST x86 microkernel
 ' Copyright (C) 2010-2016  Stefan Schmidt
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
#include "interrupt.bi"
#include "apic.bi"
#include "process.bi"
#include "syscall.bi"
#include "panic.bi"
#include "pmm.bi"
#include "kmm.bi"

DECLARE_LIST(irq_handler_type)
DEFINE_LIST(irq_handler_type)

type irq_handler_type
	process as process_type ptr
	handler as any ptr

	list as Listtype(irq_handler_type) = Listtype(irq_handler_type)(offsetof(irq_handler_type, list))

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

dim shared irq_handlers(0 to 15) as Listtype(irq_handler_type)

function register_irq_handler (process as process_type ptr, irq as integer, handler_address as any ptr) as boolean
	if ((irq < lbound(irq_handlers,1)) or (irq > ubound(irq_handlers,1))) then return false

	dim h as irq_handler_type ptr = new irq_handler_type(process, handler_address)
	irq_handlers(irq).insert_after(@h->list)

    '' FIXME: hardcoding the x86 IRQ-offset? naaaaaaah....
	interrupt_unmask(irq+&h20)
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
			if (interrupt_is_spurious(isf->int_nr)) then
                '' takes care of spurious interrupts and sends EOI if needed
                interrupt_eoi(isf->int_nr)
				return isf
			end if

			'' mask the IRQ to prevent it from firing again (gets unmasked when the thread is done)
			'' even when no popup-thread was created we mask to prevent IRQ-storms
			interrupt_mask(isf->int_nr)

			'' IRQ
			list_foreach(h, irq_handlers(isf->int_nr-&h20))
				dim x as irq_handler_type ptr = h->get_owner()
				dim thread as thread_type ptr = new thread_type(x->process, x->handler, 1, THREAD_FLAG_POPUP)

				dim stack_p as any ptr = vmm_resolve(@(thread->parent_process->context), thread->stack_area->address + (thread->stack_area->pages-1)*PAGE_SIZE)
				dim m as uinteger ptr = vmm_kernel_automap(cast(any ptr, stack_p), PAGE_SIZE)
				m[PAGE_SIZE\4-1] = isf->int_nr-&h20
				m[PAGE_SIZE\4-2] = 0  '' return address, needed because of cdecl!
				vmm_kernel_unmap(m, PAGE_SIZE)
				thread->isf->esp -= 8

				thread->activate()
			list_next(h)

        case &h20                                           '' timer IRQ
			reschedule = true

        case &hFF                                          '' syscall interrupt
            isf->eax = syscall_handler(isf->eax, isf->ebx, isf->esi, isf->edi)

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

    '' important: send EOI if necessary
    interrupt_eoi(isf->int_nr)

    return get_current_thread()->isf
end function
