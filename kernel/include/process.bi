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

#pragma once

#include "isf.bi"
#include "vmm.bi"
#include "elf32.bi"
#include "multiboot.bi"
#include "thread.bi"
#include "spinlock.bi"
#include "address_space.bi"
#include "vfs.bi"

DECLARE_LIST(process_type)

type process_type
	id as uinteger
	
	parent as process_type ptr
	
	context as vmm_context
	
	a_s as address_space
	
	state as ubyte
	
	ipc_handler as any ptr
	
	io_bitmap as uinteger ptr
	
	thread_list as Listtype(thread_type)
	next_tid as uinteger
	tid_lock as spinlock
	
	process_list as Listtype(process_type) = Listtype(process_type)(offsetof(process_type, process_list))
	
	file_descriptors as Listtype(vfs_fd)
	
	declare operator new (size as uinteger) as any ptr
	declare operator new[] (size as uinteger) as any ptr
	declare operator delete (buffer as any ptr)
	
	declare constructor (parent as process_type ptr = 0)
	declare function get_tid () as uinteger
end type

declare sub process_remove_thread (thread as thread_type ptr)
declare sub process_destroy (process as process_type ptr)
