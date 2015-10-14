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

#include "kernel.bi"
#include "syscall.bi"
#include "process.bi"
#include "video.bi"
#include "io_man.bi"
#include "panic.bi"
#include "interrupt_handler.bi"
#include "pic.bi"
#include "vfs.bi"


function syscall_handler (funcNumber as uinteger, param1 as uinteger, param2 as uinteger, param3 as uinteger) as uinteger
	dim cur_thread as thread_type ptr = get_current_thread()
	
	select case (funcNumber)
		case SYSCALL_PROCESS_GET_PID
			return cur_thread->parent_process->id
		
		case SYSCALL_PROCESS_GET_PARENT_PID
			if (cur_thread->parent_process->parent <> nullptr) then
				return cur_thread->parent_process->parent->id
			else
				return 0
			end if
		
		case SYSCALL_PROCESS_CREATE
			'' TODO: implement
		
		case SYSCALL_PROCESS_EXIT
			'' TODO: implement
		
		case SYSCALL_PROCESS_KILL
			'' TODO: implement
		
		case SYSCALL_THREAD_GET_TID
			return cur_thread->id
		
		case SYSCALL_THREAD_CREATE
			'' param1 = entrypoint for the thread
			'' param2 = usermode stack size for the thread in pages
			'' FIXME: don't hardcode these values!
			if ((param1 < &h40000000)) then return false
			
			dim thread as thread_type ptr = new thread_type(cur_thread->parent_process, cast(any ptr, param1), param2)
			if (thread <> nullptr) then
				thread->activate()
				return true
			else
				return false
			end if
		
		case SYSCALL_THREAD_SLEEP
			'' TODO: implement
		
		case SYSCALL_THREAD_YIELD
			cur_thread->flags or= THREAD_FLAG_RESCHEDULE
		
		case SYSCALL_THREAD_EXIT
			cur_thread->destroy()
		
		case SYSCALL_MEMORY_ALLOCATE_PHYSICAL:
			'' bytes, addr, flags
			'' FIXME: not entirely correct, remember page alignment!
			''       - also, don't just allow userspace to map everything!
			'asm hlt
			return cuint(vmm_automap(@cur_thread->parent_process->context, cast(any ptr, param2), param1, &h40000000, &hFFFFFFFF, VMM_FLAGS.USER_DATA))
		
		case SYSCALL_PORT_REQUEST
			if (request_port(cur_thread->parent_process, param1)) then
				set_io_bitmap()
				return true
			end if
			
			return false
		
		case SYSCALL_PORT_RELEASE
			if (release_port(cur_thread->parent_process, param1)) then
				set_io_bitmap()
				return true
			end if
			
			return false
		
		case SYSCALL_IRQ_HANDLER_REGISTER
			return register_irq_handler(cur_thread->parent_process, param1, cast(any ptr, param2))
		
		case SYSCALL_IRQ_HANDLER_EXIT
			pic_unmask(param1)
			cur_thread->destroy()
		
		case SYSCALL_IPC_HANDLER_CALL
			'' TODO: implement
			'' param1 = target pid
			
		
		case SYSCALL_IPC_HANDLER_SET
			cur_thread->parent_process->ipc_handler = cast(any ptr, param1)
		
		case SYSCALL_IPC_HANDLER_EXIT
			'' IPC popup threads need to be cleaned up with this syscall
			'' FIXME: what if this wasn't an IPC-thread?
			cur_thread->destroy()
			
		case SYSCALL_VFS_OPEN
			'' param1: path-string
			'' param2: flags
			'' result: filedescriptor
			'' FIXME: check path-string pointer
			dim fd as vfs_fd ptr = vfs_open(cur_thread, cast(zstring ptr, param1), param2)
			return fd->id
			
		case SYSCALL_VFS_CLOSE
			'' param1: filedescriptor
			'' resuslt: errorcode
		
		case SYSCALL_VFS_READ
		
		case SYSCALL_VFS_WRITE
		
		case SYSCALL_FORTY_TWO
			video_fout(!"The answer to life, the universe and everything is... 42\n")
			
		case 43
			video_fout(!"%z\n", param1)
		
		case else:
			panic_error("Undefined syscall called!")
	end select
end function
