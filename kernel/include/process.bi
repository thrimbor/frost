#pragma once

#include "isf.bi"
#include "vmm.bi"
#include "elf32.bi"
#include "multiboot.bi"
#include "thread.bi"


type process_type
	id as uinteger
	
	parent as process_type ptr
	
	vmm_context as vmm.context
	
	next_stack as uinteger
	
	state as UBYTE
	
	rpc_handler as any ptr
	
	io_bitmap as uinteger ptr
	
	threads as thread_type ptr
	next_tid as uinteger
	
	prev_process as process_type ptr
	next_process as process_type ptr
end type

declare function process_create (parent as process_type ptr = 0) as process_type ptr

/'
namespace tasks
    
    
    declare function generate_pid () as uinteger
    declare function init_task (entry as any ptr) as task_type ptr
    
    declare function get_current_task () as task_type ptr
    declare function get_current_thread () as thread_type ptr
    declare sub init_elf (image as any ptr)
    declare sub create_tasks_from_mb (mbinfo as multiboot_info ptr)
end namespace
'/
