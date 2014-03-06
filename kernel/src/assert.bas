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

#include "video.bi"

#if defined (FROST_DEBUG)
	sub _fb_Assert alias "fb_Assert" (byval fname as zstring ptr, byval linenum as integer, byval funcname as zstring ptr, byval expression as zstring ptr)
		video_fout(!"%z(%i): assertion failed at %z: %z\n", fname, linenum, funcname, expression)
		asm cli
		asm hlt
	end sub

	sub _fb_AssertWarn alias "fb_AssertWarn" (byval fname as zstring ptr, byval linenum as integer, byval funcname as zstring ptr, byval expression as zstring ptr)
		video_fout(!"%z(%i): assertion failed at %z: %z\n", fname, linenum, funcname, expression)
	end sub
#endif
