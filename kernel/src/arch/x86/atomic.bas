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

#include "atomic.bi"

sub AtomicInt.inc ()
    asm
        mov ebx, [this+offsetof(AtomicInt, counter)]
        lock inc dword ptr [ebx]
    end asm
end sub

sub AtomicInt.dec ()
    asm
        mov ebx, [this+offsetof(AtomicInt, counter)]
        lock dec dword ptr [ebx]
    end asm
end sub

function AtomicInt.add (val as integer) as integer
    asm
        mov ebx, [val]
        mov eax, [this+offsetof(AtomicInt, counter)]
        lock xadd dword ptr [eax], ebx
        mov [function], ebx
    end asm
end function

function AtomicInt.get () as integer
    return this.counter
end function
