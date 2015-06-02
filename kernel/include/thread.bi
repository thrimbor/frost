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
#include "intrusive_list.bi"
#include "address_space.bi"

const THREAD_STATE_DISABLED = 0
const THREAD_STATE_RUNNING = 1
const THREAD_STATE_BLOCKED = 2
const THREAD_STATE_KILL_ON_SCHEDULE = 3

const THREAD_FLAG_POPUP = 1
const THREAD_FLAG_RESCHEDULE = 2

type process_type_ as process_type

type thread_type
	parent_process as process_type_ ptr
	
	id as uinteger
	flags as uinteger
	state as uinteger
	
	kernelstack_p as any ptr
	kernelstack_bottom as any ptr
	userstack_p as any ptr
	userstack_bottom as any ptr
	stack_area as address_space_area ptr
	isf as interrupt_stack_frame ptr

	'' list of threads of a process
	process_threads as list_head
	
	'' list of active threads
	active_threads as list_head
	
	declare operator new (size as uinteger) as any ptr
	declare operator new[] (size as uinteger) as any ptr
	declare operator delete (buffer as any ptr)
	
	declare constructor (process as process_type_ ptr, entry as any ptr, userstack_pages as uinteger, flags as ubyte = 0)
	declare sub activate ()
	declare sub deactivate ()
	declare sub destroy ()
	
end type

declare function schedule (isf as interrupt_stack_frame ptr) as thread_type ptr
declare sub thread_switch (isf as interrupt_stack_frame ptr)
declare function get_current_thread () as thread_type ptr
declare sub thread_create_idle_thread ()
declare sub set_io_bitmap ()
