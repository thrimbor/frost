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

#include "kernel.bi"
#include "multiboot.bi"

namespace pmm
    const PAGE_SIZE = 4096
    
    declare sub init (mbinfo as multiboot_info ptr)
    declare function alloc (num_pages as uinteger = 1) as any ptr
    declare sub free (page as any ptr, num_pages as uinteger = 1)
    declare sub mark_used (page as any ptr)
    declare function get_total () as uinteger
    declare function get_free () as uinteger
end namespace
