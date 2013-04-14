#include "thread.bi"
#include "process.bi"
#include "pmm.bi"
#include "vmm.bi"
#include "kmm.bi"
#include "mem.bi"
#include "panic.bi"

'' linked list of running threads
dim shared running_threads as thread_type ptr = nullptr
dim shared current_thread as thread_type ptr = nullptr

function generate_tid (process as process_type ptr) as uinteger
	dim tid as uinteger
	
	spinlock_acquire(@process->tid_lock)
	tid = process->next_tid
	process->next_tid += 1
	spinlock_release(@process->tid_lock)
	
	return tid
end function
	

function thread_create (process as process_type ptr, entry as any ptr) as thread_type ptr
	dim thread as thread_type ptr = kmalloc(sizeof(thread_type))
	
	'' check if we could not reserve memory
	if (thread = 0) then return 0
	
	'' assign id
	thread->id = generate_tid(process)
	
	'' set owning process
	thread->parent_process = process
	
	'' set state
	thread->state = THREAD_STATE_DISABLED
	
	'' insert it into the list of the process
	thread->next_thread = process->threads
	process->threads = thread
	
	'' the kernel stack has to be in kernel space
	'' reserve space for the stacks
	dim phys_kernel_stack as any ptr = pmm.alloc()
	dim phys_user_stack as any ptr = pmm.alloc()
	
	'' map the kernel stack into the kernel's address space (unreachable from userspace)
	thread->kernelstack_bottom = vmm.kernel_automap(phys_kernel_stack, pmm.PAGE_SIZE)
	
	'' set the virtual adress of the usermode stack
	process->next_stack -= pmm.PAGE_SIZE
	thread->userstack_bottom = cast(any ptr, process->next_stack)
	
	'' map the usermode stack to the context of the process
	vmm.map_page(@process->vmm_context, thread->userstack_bottom, phys_user_stack, (vmm.PTE_FLAGS.PRESENT or vmm.PTE_FLAGS.WRITABLE or vmm.PTE_FLAGS.USERSPACE))
	
	'' create a pointer to the isf
	dim isf as interrupt_stack_frame ptr = thread->kernelstack_bottom + pmm.PAGE_SIZE - sizeof(interrupt_stack_frame)
	
	'' clear the whole structure
	memset(isf, 0, sizeof(interrupt_stack_frame))
	
	'' initialize the isf
	isf->eflags = &h0202
	isf->eax = 0
	isf->ebx = 0
	isf->ecx = 0
	isf->edx = 0
	isf->esi = 0
	isf->edi = 0
	isf->ebp = 0
	isf->eip = cuint(entry)
	isf->esp = cuint(thread->userstack_bottom) + pmm.PAGE_SIZE
	isf->cs = &h18 or &h03
	isf->ss = &h20 or &h03
	
	'' activate thread and put it in the active list
	thread_activate(thread)
	
	'' we're done
	return thread
end function

sub thread_activate (thread as thread_type ptr)
	if (thread->state = THREAD_STATE_RUNNING) then panic_error("Kernel tried to activate an already activated thread!")
	
	'' set the state
	thread->state = THREAD_STATE_RUNNING
	
	'' insert it into the running-thread-list
	thread->next_thread = running_threads
	running_threads = thread
end sub

function schedule (isf as interrupt_stack_frame ptr) as thread_type ptr
	if (current_thread <> 0) then
		current_thread->isf = isf
		current_thread = current_thread->next_thread
	end if
	
	if (current_thread = 0) then current_thread = running_threads
	
	if (current_thread = 0) then
		'' we should active an idle-thread here
		panic_error(!"There is no active thread to run!")
	end if
	
	return current_thread
end function
