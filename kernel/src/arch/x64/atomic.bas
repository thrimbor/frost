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
        mov rbx, [this+offsetof(AtomicInt, counter)]
        lock inc qword ptr [rbx]
    end asm
end sub

sub AtomicInt.dec ()
    asm
        mov rbx, [this+offsetof(AtomicInt, counter)]
        lock dec qword ptr [rbx]
    end asm
end sub

function AtomicInt.add (val as integer) as integer
    asm
        mov rbx, [val]
        mov rax, [this+offsetof(AtomicInt, counter)]
        lock xadd qword ptr [rax], rbx
        mov [function], rbx
    end asm
end function

function AtomicInt.get () as integer
    return this.counter
end function
