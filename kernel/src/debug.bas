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

#include "debug.bi"
#include "kernel.bi"
#include "video.bi"

    
'' this function allows a loglevel to be set which is used by a wrapper for the video-code
sub debug_set_loglevel (level as ubyte)
	debug_loglevel = level
end sub

#if defined (FROST_DEBUG)
	dim shared debug_com_initialized as boolean = false
	
	sub debug_init_com (baseport as ushort, baud as uinteger, parity as ubyte, bits as ubyte)
		baud = 115200\baud
		
		out(baseport+1, 0)
		
		out(baseport+3, &h80)
		
		out(baseport, lobyte(baud))
		out(baseport+1, hibyte(baud))
		
		out(baseport+3, ((parity and &h07) shl 3) or ((bits-5) and &h03))
		
		out(baseport+2, &hC7)
		out(baseport+4, &h0B)
	end sub
	
	sub debug_serial_init ()
		debug_init_com(&h3F8, 19200, 0, 8)
		debug_com_initialized = true
	end sub
	
	sub debug_serial_putc (char as ubyte)
		if (debug_com_initialized) then
			while((inp(&h3F8+5) and &h20) = 0) : wend
			out(&h3F8, char)
		end if
	end sub
#endif

sub debug_stacktrace (maxFrames as uinteger)
	dim ebp as uinteger ptr = @maxFrames -2
	
	ebp = cast(uinteger ptr, ebp)
	
	video.fout(!"stacktrace\n")
	for frame as uinteger = 0 to maxFrames
		dim eip as uinteger = ebp[1]
		
		if (eip = 0) or (ebp = nullptr) then
			exit for
		end if
		
		ebp = cast(uinteger ptr, ebp[0])
		video.fout(!" 0x%h########I\n", eip)
	next
end sub
