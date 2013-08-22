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

#define num_pages(n) (((n + &hFFF) and (&hFFFFF000)) shr 12)

namespace vmm
    '' flags for page-table-entries
    enum PTE_FLAGS explicit
		PRESENT       = &h1
		WRITABLE      = &h2
		USERSPACE     = &h4
		WRITETHROUGH  = &h8
		NOT_CACHEABLE = &h10
		ACCESSED      = &h20
		DIRTY         = &h40
		PAT           = &h80
		GLOBAL        = &h100
    end enum
	
	'' flags for page-directory-entries
	enum PDE_FLAGS explicit
		PRESENT       = &h1
		WRITABLE      = &h2
		USERSPACE     = &h4
		WRITETHROUGH  = &h8
		NOT_CACHEABLE = &h10
		ACCESSED      = &h20
		DIRTY         = &h40
		FOUR_MB       = &h80
		GLOBAL        = &h100
	end enum
    
    '' the kernels address space is from 0-1 gb, so we put the kernels pagetables at 1gb-4mb
    const PAGETABLES_VIRT_START as uinteger = &h3FC00000
    const PAGE_MASK as uinteger = &hFFFFF000
    
    #define GET_PAGEDIR_INDEX(x) ((cuint(x) shr 22) and &h3FF)
    #define GET_PAGETABLE_INDEX(x) ((cuint(x) shr 12) and &h3FF)
    
    type context
		version as uinteger         '' important to keep the kernel section up to date
		p_pagedir as uinteger ptr   '' physical address of the pagedir, needed for the cpu
		v_pagedir as uinteger ptr   '' virtual address of the pagedir, needed to access the pagedir later
	end type
    
    declare sub init ()
    declare function alloc (v_addr as any ptr) as boolean
    declare sub context_initialize (cntxt as context ptr)
    declare function map_page (cntxt as context ptr, virtual as any ptr, physical as any ptr, flags as uinteger) as boolean
    declare function map_range (cntxt as context ptr, v_addr as any ptr, p_start as any ptr, p_end as any ptr, flags as uinteger) as boolean
    declare function kernel_automap (p_start as any ptr, size as uinteger) as any ptr
    declare sub kernel_unmap (v_start as any ptr, size as uinteger)
    declare function resolve (cntxt as context ptr, vaddr as any ptr) as any ptr
    declare sub activate_context (cntxt as context ptr)
    declare function get_current_context () as context ptr
    declare sub activate ()
end namespace
