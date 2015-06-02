/'
 ' FROST x86 microkernel
 ' Copyright (C) 2010-2015  Stefan Schmidt
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
    static pid_lock as spinlock		 '' spinlock to protect concurrent access
    
    dim pid as uinteger              '' the generated pid
    
    pid_lock.acquire()  		     '' acquire lock
    pid = next_pid                   '' save pid
    next_pid += 1                    '' increase pid counter
    pid_lock.release() 			     '' release lock
    
    return pid                       '' return generated pid
end function

dim shared processlist as list_head

operator process_type.new (size as uinteger) as any ptr
	return kmalloc(size)
	'' constructor is called automatically
end operator

operator process_type.delete (buffer as any ptr)
	kfree(buffer)
	'' destructor is called automatically
end operator

constructor process_type (parent as process_type ptr = 0)
	'' assign a process-ID
	this.id = generate_pid()
	
	'' set parent
	this.parent = parent
	
	this.ipc_handler = nullptr
	this.io_bitmap = nullptr
	
	'' insert the process into the list
	processlist.insert_before(@this.process_list)
	
	'' create a vmm-context
	vmm_context_initialize(@this.context)
end constructor

function process_type.get_tid () as uinteger
	this.tid_lock.acquire()
	
	function = this.next_tid
	this.next_tid += 1
	
	this.tid_lock.release()
end function

sub process_remove_thread (thread as thread_type ptr)
	thread->process_threads.remove()
end sub
