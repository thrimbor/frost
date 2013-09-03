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

namespace syscall
    
    function handler (param1 as uinteger, param2 as uinteger, param3 as uinteger, param4 as uinteger) as uinteger
        dim cur_thread as thread_type ptr = get_current_thread()
        
        select case (param1)
            case syscall.PROCESS_GET_PID
                return cur_thread->parent_process->id
            case syscall.PROCESS_GET_PARENT_PID
				if (cur_thread->parent_process->parent <> nullptr) then
					return cur_thread->parent_process->parent->id
				else
					return 0
				end if
			case syscall.PROCESS_CREATE
				'' TODO: implement
			case syscall.PROCESS_EXIT
				'' TODO: implement
			case syscall.PROCESS_KILL
				'' TODO: implement
			case syscall.THREAD_GET_TID
				return cur_thread->id
			case syscall.THREAD_CREATE
				'' TODO: implement
			case syscall.THREAD_SLEEP
				'' TODO: implement
			case syscall.THREAD_EXIT
				'' TODO: implement
			case syscall.PORT_REQUEST
				request_port(cur_thread->parent_process, param2)
				set_io_bitmap()
			case syscall.PORT_RELEASE
				release_port(cur_thread->parent_process, param2)
				set_io_bitmap()
			case syscall.SET_INTERRUPT_HANDLER
				'' TODO: implement
			case syscall.RPC_SET_HANDLER
				'' TODO: implement
			case syscall.RPC_CALL
				'' TODO: implement
			case syscall.RPC_WAIT_FOR_CALL
				'' TODO: implement
            case syscall.FORTY_TWO
                video.fout(!"The answer to life, the universe and everything is... 42\n")
            case 43
				video.fout(!"%z\n", param2)
        end select
    end function
    
end namespace
