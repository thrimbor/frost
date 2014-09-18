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

'' flags for page-table-entries
enum VMM_PTE_FLAGS explicit
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
enum VMM_PDE_FLAGS explicit
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

enum VMM_FLAGS explicit
	USER_DATA     = VMM_PTE_FLAGS.PRESENT or VMM_PTE_FLAGS.WRITABLE or VMM_PTE_FLAGS.USERSPACE
	KERNEL_DATA   = VMM_PTE_FLAGS.PRESENT or VMM_PTE_FLAGS.WRITABLE
end enum

'' the kernels address space is from 0-1 gb, so we put the kernels pagetables at 1gb-4mb
const VMM_PAGETABLES_VIRT_START as uinteger = &h3FC00000
const VMM_PAGE_MASK as uinteger = &hFFFFF000

type vmm_context
	version as uinteger         '' important to keep the kernel section up to date
	p_pagedir as uinteger ptr   '' physical address of the pagedir, needed for the cpu
	v_pagedir as uinteger ptr   '' virtual address of the pagedir, needed to access the pagedir later
end type

declare sub vmm_init ()
declare sub vmm_init_local ()
declare function vmm_alloc (v_addr as any ptr) as boolean
declare sub vmm_context_initialize (cntxt as vmm_context ptr)
declare function vmm_map_page (cntxt as vmm_context ptr, virtual as any ptr, physical as any ptr, flags as uinteger) as boolean
declare function vmm_map_range (cntxt as vmm_context ptr, v_addr as any ptr, p_start as any ptr, p_end as any ptr, flags as uinteger) as boolean
declare sub vmm_unmap_range (cntxt as vmm_context ptr, v_addr as any ptr, pages as uinteger)
declare function vmm_automap (context as vmm_context ptr, p_start as any ptr, size as uinteger, lowerLimit as uinteger, upperLimit as uinteger, flags as uinteger) as any ptr
declare function vmm_kernel_automap (p_start as any ptr, size as uinteger) as any ptr
declare sub vmm_kernel_unmap (v_start as any ptr, size as uinteger)
declare function vmm_resolve (cntxt as vmm_context ptr, vaddr as any ptr) as any ptr
declare sub vmm_activate_context (cntxt as vmm_context ptr)
declare function vmm_get_current_context () as vmm_context ptr
