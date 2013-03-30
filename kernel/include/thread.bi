#pragma once

#include "isf.bi"

const THREAD_STATE_DISABLED = 0
const THREAD_STATE_RUNNING = 1
const THREAD_STATE_BLOCKED = 2

const THREAD_MAX_TICKS = 50

type process_type_ as process_type

type thread_type
	parent_process as process_type_ ptr
	
	id as uinteger
	state as ubyte
	
	kernelstack_bottom as any ptr
	userstack_bottom as any ptr
	isf as interrupt_stack_frame ptr
	
	ticks_left as uinteger
	ticks_max as uinteger
	
	'prev_thread as thread_type ptr
	next_thread as thread_type ptr
	
	prev_active_thread as thread_type ptr
	next_active_thread as thread_type ptr
end type

declare function thread_create (process as process_type_ ptr, entry as any ptr) as thread_type ptr
declare sub thread_activate (thread as thread_type ptr)
declare function schedule (isf as interrupt_stack_frame ptr) as thread_type ptr
