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

#pragma once

#include "isf.bi"
#include "vmm.bi"
#include "elf32.bi"
#include "multiboot.bi"
#include "thread.bi"
#include "spinlock.bi"


type process_type
	id as uinteger
	
	parent as process_type ptr
	
	vmm_context as vmm.context
	
	state as UBYTE
	
	rpc_handler as any ptr
	
	io_bitmap as uinteger ptr
	
	threads as thread_type ptr
	next_tid as uinteger
	tid_lock as spinlock
	
	prev_process as process_type ptr
	next_process as process_type ptr
end type

declare function process_create (parent as process_type ptr = 0) as process_type ptr
