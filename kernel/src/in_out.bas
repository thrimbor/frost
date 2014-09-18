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

'' this code is a bit strange, but it's the only comfortable way to use in/out in FreeBASIC without the rtlib (which can't be used in a kernel)

sub outb (port as ushort, value as ubyte)
    asm
        movw dx, [port]
        movb al, [value]
        outb dx, al
    end asm
end sub

function inb (port as ushort) as ubyte
    asm
        movw dx, [port]
        inb al, dx
        mov [function], al
    end asm
end function
