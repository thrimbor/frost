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

#include "kernel.bi"
#include "isf.bi"
#include "video.bi"

namespace panic
	common shared clear_on_panic as boolean
    declare sub set_clear_on_panic (b as boolean)
    declare sub hlt ()
    declare sub panic_exception (isf as interrupt_stack_frame ptr)
    
    #macro panic_error (msg, params...)
		asm cli
		video.set_color(0,3)
		if (panic.clear_on_panic) then video.clean(3)
		video.fout(!"\nKERNEL PANIC\n")
		video.fout(!"file: %z, function: %z, line: %I\n\n", @__FILE__, @__FUNCTION__, cuint(__LINE__))
		video.fout(!"reason: ")
		video.fout(msg, params)
		
		panic.hlt()
	#endmacro
end namespace
