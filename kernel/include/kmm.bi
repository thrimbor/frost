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

const HEAP_MAGIC as uinteger = &hDEADBEEF

type kmm_header field = 1
    magic as uinteger             '' magic number to identify blocks
    is_hole as ubyte              '' true if this is a hole, false if this is a block
    size as uinteger              '' size of the "content-area" of the block
end type

type kmm_content field = 1
    prev_entry as kmm_header ptr  '' pointer to the previous entry in the linked list
    next_entry as kmm_header ptr  '' pointer to the next entry in the linked list
end type

type kmm_footer field = 1
    magic as uinteger             '' magic number to identify footers
    header as kmm_header ptr      '' pointer to the block-header
end type

declare sub kmm_init (start_addr as uinteger, end_addr as uinteger, minimum as uinteger, maximum as uinteger)
declare function kmalloc (size as uinteger) as any ptr
declare sub kfree (addr as any ptr)
