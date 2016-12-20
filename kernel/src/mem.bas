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

#include "mem.bi"

sub memcpy (destination as any ptr, source as any ptr, size as uinteger)
    asm
        mov ecx, [size]
        mov edi, [destination]
        mov esi, [source]
        
        rep movsb
    end asm
end sub

sub memset (destination as any ptr, value as ubyte, size as uinteger)
    asm
        mov ecx, [size]
        mov edi, [destination]
        mov al, [value]
        
        rep stosb
    end asm
end sub

function memcmp (s1 as any ptr, s2 as any ptr, size as uinteger) as integer
	dim p1 as ubyte ptr = s1
	dim p2 as ubyte ptr = s2
	
	while (size > 0)
		if (*p1 <> *p2) then
			return *p1 - *p2
		end if
		
		p1 += 1
		p2 += 1
		size -= 1
	wend
	
	return 0
end function
