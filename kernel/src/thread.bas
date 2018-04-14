/'
 ' FROST x86 microkernel
 ' Copyright (C) 2010-2017  Stefan Schmidt
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

#include "thread.bi"
#include "process.bi"
#include "pmm.bi"
#include "vmm.bi"
#include "kmm.bi"
#include "mem.bi"
#include "panic.bi"
#include "video.bi"
#include "modules.bi"

DEFINE_LIST(thread_type)

'' linked list of running threads
dim shared running_threads_list as Listtype(thread_type)
dim shared current_thread as thread_type ptr = nullptr
dim shared idle_thread as thread_type ptr

operator thread_type.new (size as uinteger) as any ptr
	return kmalloc(size)
	'' constructor is called automatically
end operator

operator thread_type.delete (buffer as any ptr)
	kfree(buffer)
	'' destructor is called automatically
end operator

constructor thread_type (process as process_type ptr, entry as any ptr, userstack_pages as uinteger, flags as ubyte = 0)
	'' assign id
	this.id = process->get_tid()

	'' set owning process
	this.parent_process = process

	'' set flags
	this.flags = flags

	'' set state
	this.state = THREAD_STATE_DISABLED

	'' insert it into the list of the process
	process->thread_list.insert_before(@this.process_threads)

	'' allocate a virtual memory area for the stack
	this.stack_area = process->a_s.allocate_area(userstack_pages)

	'' reserve physical memory and map the area
	for pagecounter as uinteger = 1 to userstack_pages
		dim p_addr as any ptr = pmm_alloc()
		dim v_addr as uinteger = cuint(this.stack_area->address) + (pagecounter-1)*PAGE_SIZE

		vmm_map_page(@process->context, cast(any ptr, v_addr), p_addr, VMM_FLAGS.USER_DATA)
	next

	'' reserve space for the kernel-stack
	this.kernelstack_p = pmm_alloc()

	'' map the kernel stack into the kernel's address space (unreachable from userspace)
	this.kernelstack_bottom = vmm_kernel_automap(this.kernelstack_p, PAGE_SIZE)

	'' create a pointer to the isf
	dim isf as interrupt_stack_frame ptr = this.kernelstack_bottom + PAGE_SIZE - sizeof(interrupt_stack_frame)
	this.isf = isf

	'' clear the whole structure
	memset(isf, 0, sizeof(interrupt_stack_frame))

	'' initialize the isf
	isf->eflags = &h0202
	isf->eip = cuint(entry)
	isf->esp = cuint(this.stack_area->address) + this.stack_area->pages*PAGE_SIZE
	isf->cs = &h18 or &h03
	isf->ss = &h20 or &h03
end constructor

sub thread_type.destroy ()
	if (current_thread = @this) then
		this.state = THREAD_STATE_KILL_ON_SCHEDULE
		this.flags or= THREAD_FLAG_RESCHEDULE
		return
	end if

	'' remove thread from the active thread list
	this.deactivate()

	'' remove thread from the threadlist of the process
	process_remove_thread(@this)

	'' unmap kernelstack
	vmm_unmap_range(@this.parent_process->context, this.kernelstack_bottom, 1)

	'' free kernelstack
	pmm_free(this.kernelstack_p)

	'' free the physical memory of the userspace stack
	for pagecounter as uinteger = 1 to this.stack_area->pages
		dim p_stack as any ptr = vmm_resolve(@this.parent_process->context, this.stack_area->address + (pagecounter-1)*PAGE_SIZE)
		pmm_free(p_stack)
	next

	'' unmap the userspace stack
	vmm_unmap_range(@this.parent_process->context, this.stack_area->address, this.stack_area->pages)

	'' delete the address space area
	delete this.stack_area

	'' free thread structure
	kfree(@this)
end sub

sub thread_type.activate ()
	if (this.state = THREAD_STATE_RUNNING) then
		panic_error("Kernel tried to activate an already activated thread!")
	end if

	'' set the state
	this.state = THREAD_STATE_RUNNING

	'' insert it into the running-thread-list
	running_threads_list.insert_before(@this.active_threads)
end sub

sub thread_type.deactivate ()
	this.state = THREAD_STATE_DISABLED

	this.active_threads.remove()
end sub

sub thread_type.push_mem (mem as any ptr, length as uinteger)
    dim stack_p as any ptr = vmm_resolve(@(this.parent_process->context), this.stack_area->address + (this.stack_area->pages-1)*PAGE_SIZE)
    dim m as ubyte ptr = vmm_kernel_automap(cast(any ptr, stack_p), PAGE_SIZE)

    memcpy(m+PAGE_SIZE-length, mem, length)
    vmm_kernel_unmap(m, PAGE_SIZE)
    this.isf->esp -= length
end sub

function schedule (isf as interrupt_stack_frame ptr) as thread_type ptr
	dim new_thread as thread_type ptr = current_thread

	dim it as Listtype(thread_type) ptr = iif(current_thread, @current_thread->active_threads, @running_threads_list)
	while (not running_threads_list.is_empty())
		it = it->get_next()
		if (it = @running_threads_list) then continue while

		dim t as thread_type ptr = it->get_owner()

		if (t->state = THREAD_STATE_KILL_ON_SCHEDULE) then
			t->destroy()
			continue while
		end if

		new_thread = t
		exit while
	wend

	if (running_threads_list.is_empty()) then
		new_thread = idle_thread
	end if

	if (current_thread <> nullptr) then
		if (new_thread->parent_process <> current_thread->parent_process) then
			'' IO bitmaps are process-wide, so unload the bitmap on process switch
			tss_ptr->io_bitmap_offset = TSS_IO_BITMAP_NOT_LOADED
		end if
	end if

	current_thread = new_thread

	return new_thread
end function

sub thread_switch (isf as interrupt_stack_frame ptr)
	dim old_process as process_type ptr = nullptr
	if (get_current_thread() <> nullptr) then
		old_process = get_current_thread()->parent_process
	end if

	dim new_thread as thread_type ptr = schedule(isf)  '' select a new thread

	'' set his esp0 in the tss
	tss_ptr->esp0 = cuint(new_thread->isf) + sizeof(interrupt_stack_frame)
    '' set the esp0 for fast syscalls
    write_msr(MSR_IA32_SYSENTER_ESP, cuint(new_thread->isf) + sizeof(interrupt_stack_frame))

	'' load the new pagedir
	if ((new_thread->parent_process <> old_process) and (new_thread <> idle_thread)) then
		vmm_activate_context(@new_thread->parent_process->context)
	end if
end sub

function get_current_thread () as thread_type ptr
	return current_thread
end function

sub thread_idle ()
	do
		asm hlt
	loop
end sub

sub thread_create_idle_thread ()
	idle_thread = new thread_type(init_process, @thread_idle, 0)
	idle_thread->isf->cs = &h08
	idle_thread->isf->ss = &h10

	'' don't use thread_activate here, it's not a normal thread
	idle_thread->state = THREAD_STATE_RUNNING
end sub

sub set_io_bitmap ()
	tss_ptr->io_bitmap_offset = TSS_IO_BITMAP_OFFSET

	if (current_thread->parent_process->io_bitmap <> nullptr) then
		memcpy(@tss_ptr->io_bitmap(0), current_thread->parent_process->io_bitmap, &hFFFF\8)
	else
		memset(@tss_ptr->io_bitmap(0), &hFF, &hFFFF\8)
	end if
end sub
