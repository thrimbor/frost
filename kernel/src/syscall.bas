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

#include "kernel.bi"
#include "syscall.bi"
#include "process.bi"
#include "video.bi"
#include "io_man.bi"


function syscall_handler (param1 as uinteger, param2 as uinteger, param3 as uinteger, param4 as uinteger) as uinteger
	dim cur_thread as thread_type ptr = get_current_thread()
	
	select case (param1)
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
			'' FIXME: doesn't work yet, leads to strange crashes
			'' these pointers come from userspace, so check them first!
			if ((param2 < &h40000000) or (param3 < &h40000000)) then return false
			
			if (thread_create(cur_thread->parent_process, cast(any ptr, param2), cast(any ptr, param3)) <> nullptr) then
				return true
			else
				return false
			end if
		case SYSCALL_THREAD_SLEEP
			'' TODO: implement
		case SYSCALL_THREAD_EXIT
			'' TODO: implement
		case SYSCALL_PORT_REQUEST
			request_port(cur_thread->parent_process, param2)
			set_io_bitmap()
		case SYSCALL_PORT_RELEASE
			release_port(cur_thread->parent_process, param2)
			set_io_bitmap()
		case SYSCALL_SET_INTERRUPT_HANDLER
			'' TODO: implement
		case SYSCALL_RPC_SET_HANDLER
			'' TODO: implement
		case SYSCALL_RPC_CALL
			'' TODO: implement
		case SYSCALL_RPC_WAIT_FOR_CALL
			'' TODO: implement
		case SYSCALL_FORTY_TWO
			video_fout(!"The answer to life, the universe and everything is... 42\n")
		case 43
			video_fout(!"%z\n", param2)
	end select
end function
