/'
 ' FROST x86 microkernel
 ' Copyright (C) 2010-2017  Stefan Schmidt
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

type interrupt_stack_frame field=1
    exit_with_iret as uinteger

    '' saved per asm-code:
    eax as uinteger
    ebx as uinteger
    ecx as uinteger
    edx as uinteger
    esi as uinteger
    edi as uinteger
    ebp as uinteger

    '' saved by asm-code to identify the interrupt
    int_nr as uinteger
    errorcode as uinteger

    '' saved automatically by the cpu:
    eip as uinteger
    cs as uinteger
    eflags as uinteger
    esp as uinteger
    ss as uinteger
end type
