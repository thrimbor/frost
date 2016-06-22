/'
 ' FROST x86 microkernel
 ' Copyright (C) 2010-2016  Stefan Schmidt
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

#include "atomic.bi"

sub AtomicInt.inc ()
    this.add(1)
end sub

sub AtomicInt.dec ()
    this.add(-1)
end sub

function AtomicInt.get () as integer
    return this.counter
end function

function AtomicInt.cmpxchg (oldval as integer, newval as integer) as integer
	dim result as integer
	
	asm
		mov eax, [oldval]
		mov ebx, [newval]
        mov edx, [this+offsetof(AtomicInt, counter)]
		
		lock cmpxchg dword ptr [edx], ebx
		mov [result], eax
	end asm
	
	return result
end function

function AtomicInt.add (value as integer) as integer
    dim c as integer = this.counter
    dim old as integer
    
    do
        old = this.cmpxchg(c, c+value)
        if (old = c) then exit do
        c = old
    loop
    
    return c+value
end function

function AtomicInt.subtract (value as integer) as integer
    return this.add(-value)
end function

function AtomicInt.sub_and_test (value as integer) as boolean
    return this.subtract(value) = 0
end function
