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

namespace syscall
    
    sub handler (isf as interrupt_stack_frame ptr)
        dim cur_thread as thread_type ptr = get_current_thread()
        
        select case (isf->eax)
            case syscall.PROCESS_GET_PID
                isf->ebx = cur_thread->parent_process->id
            case syscall.PROCESS_GET_PARENT_PID
				if (cur_thread->parent_process->parent = 0) then
					isf->ebx = cur_thread->parent_process->parent->id
				else
					isf->ebx = 0
				end if
            case syscall.FORTY_TWO
                video.fout(!"The answer to life, the universe and everything is... 42\n")
        end select
    end sub
    
end namespace
