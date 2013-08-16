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

#include "video.bi"

namespace debug
    const INFO as ubyte = 1
    const ERROR as ubyte = 3
    
    common shared loglevel as ubyte
    
    declare sub set_loglevel (level as ubyte)

    #macro debug_wlog(level, fstr, args...)
		if (level>debug.loglevel) then video.fout(fstr, args)
	#endmacro
end namespace
