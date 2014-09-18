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

#include "process.bi"
#include "pmm.bi"
#include "isf.bi"
#include "vmm.bi"
#include "kmm.bi"
#include "mem.bi"
#include "elf32.bi"
#include "video.bi"
#include "kernel.bi"
#include "spinlock.bi"
#include "panic.bi"

function generate_pid () as uinteger
    static next_pid as uinteger = 0  '' next process id to assign
    static pid_lock as spinlock = 0  '' spinlock to protect concurrent access
    
    dim pid as uinteger              '' the generated pid
    
    spinlock_acquire(@pid_lock)      '' acquire lock
    pid = next_pid                   '' save pid
    next_pid += 1                    '' increase pid counter
    spinlock_release(@pid_lock)      '' release lock
    
    return pid                       '' return generated pid
end function

dim shared processlist_first as process_type ptr


function process_create (parent as process_type ptr = 0) as process_type ptr
	dim process as process_type ptr = kmalloc(sizeof(process_type))
	
	if (process = 0) then return 0
	
	'' assign a process-ID
	process->id = generate_pid()
	
	'' set parent
	process->parent = parent
	
	process->ipc_handler = nullptr
	process->interrupt_handler = nullptr
	process->io_bitmap = nullptr
	process->popup_stack_mask = 0
	
	'' insert the process into the list
	process->prev_process = 0
	process->next_process = processlist_first
	if (processlist_first <> nullptr) then processlist_first->prev_process = process
	processlist_first = process
	
	'' create a vmm-context
	vmm_context_initialize(@process->context)
	
	return process
end function

sub process_remove_thread (thread as thread_type ptr)
	dim process as process_type ptr = thread->parent_process
	
	dim t as thread_type ptr = process->threads
	
	if (t = nullptr) then return '' maybe panic instead?
	
	if (t = thread) then
		process->threads = t->next_thread
		return
	end if
	
	while (t->next_thread <> nullptr)
		if (t->next_thread = thread) then
			t->next_thread = t->next_thread->next_thread
			return
		end if
		
		t = t->next_thread
	wend
end sub

sub process_destroy (process as process_type ptr)
	'' TODO: implement
end sub
