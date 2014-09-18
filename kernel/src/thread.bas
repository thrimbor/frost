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

#include "thread.bi"
#include "process.bi"
#include "pmm.bi"
#include "vmm.bi"
#include "kmm.bi"
#include "mem.bi"
#include "panic.bi"
#include "video.bi"
#include "modules.bi"

'' TODO: using doubly-linked-lists instead would result in constant insertion/removal runtime

'' linked list of running threads
dim shared running_threads as thread_type ptr = nullptr
dim shared current_thread as thread_type ptr = nullptr
dim shared idle_thread as thread_type ptr

function generate_tid (process as process_type ptr) as uinteger
	dim tid as uinteger
	
	spinlock_acquire(@process->tid_lock)
	tid = process->next_tid
	process->next_tid += 1
	spinlock_release(@process->tid_lock)
	
	return tid
end function
	
function thread_create (process as process_type ptr, entry as any ptr, v_userstack_bottom as any ptr, flags as ubyte = 0) as thread_type ptr
	dim thread as thread_type ptr = kmalloc(sizeof(thread_type))
	
	'' check if we could not reserve memory
	if (thread = 0) then return 0
	
	'' assign id
	thread->id = generate_tid(process)
	
	'' set owning process
	thread->parent_process = process
	
	'' set flags
	thread->flags = flags
	
	'' set state
	thread->state = THREAD_STATE_DISABLED
	
	'' insert it into the list of the process
	thread->next_thread = process->threads
	process->threads = thread
	
	'' reserve space for the stacks
	thread->kernelstack_p = pmm_alloc()
	
	'' map the kernel stack into the kernel's address space (unreachable from userspace)
	thread->kernelstack_bottom = vmm_kernel_automap(thread->kernelstack_p, PAGE_SIZE)
	
	'' create a pointer to the isf
	dim isf as interrupt_stack_frame ptr = thread->kernelstack_bottom + PAGE_SIZE - sizeof(interrupt_stack_frame)
	thread->isf = isf
	
	'' clear the whole structure
	memset(isf, 0, sizeof(interrupt_stack_frame))
	
	'' initialize the isf
	isf->eflags = &h0202
	isf->eip = cuint(entry)
	isf->esp = cuint(v_userstack_bottom) + PAGE_SIZE
	isf->cs = &h18 or &h03
	isf->ss = &h20 or &h03
	
	'' we're done
	return thread
end function

sub thread_destroy (thread as thread_type ptr)
	if (current_thread = thread) then
		thread->state = THREAD_STATE_KILL_ON_SCHEDULE
		return
	end if
	
	'' FIXME:
	'' the thread is expecting to be killed immediately, so it shouldn't be run any further
	'' => reschedule now!

	'' remove thread from the active thread list
	thread_deactivate(thread)
	
	'' remove thread from the threadlist of the process
	process_remove_thread(thread)
	
	'' unmap kernelstack
	vmm_unmap_range(@thread->parent_process->context, thread->kernelstack_bottom, 1)
	
	'' free kernelstack
	pmm_free(thread->kernelstack_p)
	
	if (thread->flags and THREAD_FLAG_POPUP) then
		'' popup-threads get an assigned usermode-stack, which we have to free
		dim index as uinteger = (&hFFFFE000 - cuint(thread->userstack_bottom)) \ &h1000
		
		thread->parent_process->popup_stack_mask and= not(1 shl index)
		
		vmm_unmap_range(@thread->parent_process->context, thread->userstack_bottom, 1)
		
		pmm_free(thread->userstack_p)
	end if
	
	'' free thread structure
	kfree(thread)
end sub

sub thread_deactivate (thread as thread_type ptr)
	thread->state = THREAD_STATE_DISABLED
	
	dim t as thread_type ptr = running_threads
	
	if (t = nullptr) then return
	
	if (t = thread) then
		running_threads = t->next_active_thread
		return
	end if
	
	while (t->next_active_thread <> nullptr)
		if (t->next_active_thread = thread) then
			t->next_active_thread = t->next_active_thread->next_active_thread
			return
		end if
		t = t->next_active_thread
	wend
end sub

sub thread_activate (thread as thread_type ptr)
	if (thread->state = THREAD_STATE_RUNNING) then
		panic_error("Kernel tried to activate an already activated thread!")
	end if
	
	'' set the state
	thread->state = THREAD_STATE_RUNNING
	
	'' insert it into the running-thread-list
	thread->next_active_thread = running_threads
	running_threads = thread
end sub

function spawn_popup_thread (process as process_type ptr, entrypoint as any ptr) as thread_type ptr
	if (process->popup_stack_mask = &hFFFFFFFF) then return nullptr '' TODO: errorcode?
	
	dim stack_v as any ptr = nullptr
	
	for i as uinteger = 0 to 31
		if ((process->popup_stack_mask and (1 shl i)) = 0) then
			process->popup_stack_mask or= (1 shl i)
			
			'' TODO: don't hardcode page-size
			stack_v = cast(any ptr, &hFFFFE000 - i*&h1000)
			exit for
		end if
	next
	
	dim stack_p as any ptr = pmm_alloc(1)
	
	vmm_map_page(@process->context, stack_v, stack_p, VMM_FLAGS.USER_DATA)
	
	dim thread as thread_type ptr = thread_create(process, entrypoint, stack_v, THREAD_FLAG_POPUP)
	thread->userstack_p = stack_p
	thread->userstack_bottom = stack_v
	thread_activate(thread)
	
	return thread
end function

'' TODO: putting threads that are supposed to die back in the running-list is BAD!

function schedule (isf as interrupt_stack_frame ptr) as thread_type ptr
	dim old_process as process_type ptr = nullptr
	dim new_thread as thread_type ptr = current_thread
	
	if (cuint(new_thread) <> 0) then
		old_process = new_thread->parent_process
		new_thread->isf = isf
		do
			new_thread = new_thread->next_active_thread
			
			if (new_thread = nullptr) then exit do
			
			if (new_thread->state = THREAD_STATE_KILL_ON_SCHEDULE) then
				thread_destroy(new_thread)
				continue do
			else
				exit do
			end if
		loop
	end if
	
	if (cuint(new_thread) = 0) then
		do
			new_thread = running_threads
			
			if (new_thread = nullptr) then exit do
			
			if ((new_thread = current_thread) and (new_thread->state <> THREAD_STATE_RUNNING)) then
				new_thread = nullptr
				exit do
			end if
			
			if (new_thread->state = THREAD_STATE_KILL_ON_SCHEDULE) then
				thread_destroy(new_thread)
				continue do
			else
				exit do
			end if
		loop
	end if
	
	if (cuint(new_thread) = 0) then
		'' activate idle-thread
		new_thread = idle_thread
	end if
	
	if (new_thread->parent_process <> old_process) then
		tss_ptr->io_bitmap_offset = TSS_IO_BITMAP_NOT_LOADED
	end if
	
	current_thread = new_thread
	
	return new_thread
end function

function get_current_thread () as thread_type ptr
	return current_thread
end function

sub thread_idle ()
	do
		asm hlt
	loop
end sub

sub thread_create_idle_thread ()
	idle_thread = thread_create(init_process, @thread_idle, 0)
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
