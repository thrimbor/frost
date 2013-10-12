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

type task_state_segment field=1
	backlink as uinteger
	esp0 as uinteger
	ss0 as uinteger
	esp1 as uinteger
	ss1 as uinteger
	esp2 as uinteger
	ss2 as uinteger
	cr3 as uinteger
	eip as uinteger
	eflags as uinteger
	eax as uinteger
	ecx as uinteger
	edx as uinteger
	ebx as uinteger
	esp as uinteger
	ebp as uinteger
	esi as uinteger
	edi as uinteger
	es as uinteger
	cs as uinteger
	ss as uinteger
	ds as uinteger
	fs as uinteger
	gs as uinteger
	ldt as uinteger
	trace_trap as ushort
	io_bitmap_offset as ushort
	io_bitmap(0 to 2047) as uinteger
	io_bitmap_end as ubyte
end type

const TSS_IO_BITMAP_OFFSET as ushort = cushort(cuint(@(cast(task_state_segment ptr, 0)->io_bitmap(0))))
const TSS_IO_BITMAP_NOT_LOADED as ushort = sizeof(task_state_segment)+&h100

declare sub gdt_prepare ()
declare sub gdt_load ()
