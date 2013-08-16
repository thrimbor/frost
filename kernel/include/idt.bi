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

namespace idt
    type table_descriptor field=1
        limit as ushort
        base  as uinteger
    end type
    
    type gate_descriptor field=1
        offset_low as ushort
        selector as ushort
        reserved as ubyte
        accessbyte as ubyte
        offset_high as ushort
    end type
    
    const TABLE_SIZE = &h63
    
    '' flags for the access-byte
    const FLAG_PRESENT           as ubyte = &h80
    const FLAG_PRIVILEGE_RING_3  as ubyte = &h60
    const FLAG_PRIVILEGE_RING_2  as ubyte = &h40
    const FLAG_PRIVILEGE_RING_1  as ubyte = &h20
    const FLAG_PRIVILEGE_RING_0  as ubyte = &h00
    const FLAG_SEGMENT           as ubyte = &h10
    const FLAG_TASK_GATE         as ubyte = &h05
    const FLAG_INTERRUPT_GATE_16 as ubyte = &h06
    const FLAG_INTERRUPT_GATE_32 as ubyte = &h0E
    const FLAG_TRAP_GATE_16      as ubyte = &h07
    const FLAG_TRAP_GATE_32      as ubyte = &h0F
    
    declare sub prepare ()
    declare sub load ()
    declare sub set_entry (index as ushort, offset as sub (), selector as ushort, accessbyte as ubyte)
end namespace
