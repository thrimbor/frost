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

#include "vmm.bi"
#include "pmm.bi"
#include "kmm.bi"
#include "mem.bi"
#include "kernel.bi"
#include "panic.bi"
#include "cpu.bi"

#define GET_PAGEDIR_INDEX(x) ((cuint(x) shr 22) and &h3FF)
#define GET_PAGETABLE_INDEX(x) ((cuint(x) shr 12) and &h3FF)

declare function get_pagetable (cntxt as vmm_context ptr, index as uinteger) as uinteger ptr
declare sub free_pagetable (cntxt as vmm_context ptr, table as uinteger ptr)
declare sub sync_context (cntxt as vmm_context ptr)

dim shared kernel_context as vmm_context
dim shared current_context as vmm_context ptr
dim shared paging_activated as boolean = false
dim shared paging_ready as boolean = false

dim shared latest_context as vmm_context ptr = nullptr

'' sets up the required structures and activates paging
sub vmm_init ()
	'' check prerequisites
	if (not(cpu_supports_PGE())) then
		panic_error("CPU doesn't support the Page-Global-Bit.")
	end if

	'' initialize the kernel context (only used before the first task is started)
	'' the pagedir is also automatically mapped
	kernel_context.p_pagedir = pmm_alloc()
	memset(kernel_context.p_pagedir, 0, PAGE_SIZE)
	kernel_context.v_pagedir = kernel_context.p_pagedir

	'' we need to activate the context early for kernel_context to be valid
	current_context = @kernel_context

	'' map the page tables
	kernel_context.p_pagedir[VMM_PAGETABLES_VIRT_START shr 22] = cuint(kernel_context.p_pagedir) or VMM_PTE_FLAGS.PRESENT or VMM_PTE_FLAGS.WRITABLE

	'' map the kernel 1:1
	vmm_map_range(@kernel_context, kernel_start, kernel_start, kernel_end, (VMM_PTE_FLAGS.PRESENT or VMM_PTE_FLAGS.WRITABLE or VMM_PTE_FLAGS.GLOBAL))

	'' map the video memory 1:1
	vmm_map_page(@kernel_context, cast(any ptr, &hB8000), cast(any ptr, &hB8000), (VMM_PTE_FLAGS.PRESENT or VMM_PTE_FLAGS.WRITABLE or VMM_PTE_FLAGS.GLOBAL))

	'' set the virtual address
	kernel_context.v_pagedir = cast(uinteger ptr, (VMM_PAGETABLES_VIRT_START shr 22)*4096*1024 + (VMM_PAGETABLES_VIRT_START shr 22)*4096)

	kernel_context.version = 1
	latest_context = @kernel_context

	paging_ready = true
end sub

'' loads the pagedir into cr3 and activates paging
sub vmm_init_local ()
	dim pagedir as uinteger ptr = kernel_context.p_pagedir
	asm
		'' load the page directory address
		mov ebx, [pagedir]
		mov cr3, ebx

		'' set the paging bit
		mov ebx, cr0
		or ebx, &h80000000
		mov cr0, ebx

		'' set the PGE (page global enable) bit
		mov ebx, cr4
		or ebx, &h80
		mov cr4, ebx
	end asm

	paging_activated = true
end sub

'' reserve a page and map it
function vmm_alloc (v_addr as any ptr) as boolean
	'' allocate a page
	dim page as any ptr = pmm_alloc()

	'' unsuccessful? return false
	if (page = nullptr) then return false

	'' try to map it where we need it
	if (not(vmm_map_page(current_context, v_addr, page, VMM_FLAGS.KERNEL_DATA))) then
		pmm_free(page)
		return false
	end if

	return true
end function

'' create_context () creates and clears space for a page-directory
sub vmm_context_initialize (cntxt as vmm_context ptr)
	cntxt->version = 0
	cntxt->p_pagedir = pmm_alloc()
	cntxt->v_pagedir = vmm_kernel_automap(cntxt->p_pagedir, PAGE_SIZE)
	memset(cntxt->v_pagedir, 0, PAGE_SIZE)

	'' copy the kernel address space
	sync_context(cntxt)

	'' pagetables need to be accessible
	cntxt->v_pagedir[VMM_PAGETABLES_VIRT_START shr 22] = cuint(cntxt->p_pagedir) or VMM_PTE_FLAGS.PRESENT or VMM_PTE_FLAGS.WRITABLE
end sub

sub context_destroy (cntxt as vmm_context ptr)
	'' TODO: implement
end sub

'' map_page maps a single page into a given context
function vmm_map_page (cntxt as vmm_context ptr, v_addr as any ptr, physical as any ptr, flags as uinteger) as boolean
	'' memorize if the pagetable needs to be cleared (needed when we allocate a new pagetable)
	dim clear_pagetable as boolean = false
	'' the entry in the pagedir
	dim pagedir_entry_ptr as uinteger ptr = @(cntxt->v_pagedir[GET_PAGEDIR_INDEX(v_addr)])
	if (not(paging_activated)) then pagedir_entry_ptr = @(cntxt->p_pagedir[GET_PAGEDIR_INDEX(v_addr)])

	'// multiline if because of the multiline macro - we would get strange errors otherwise
	if (v_addr = 0) then
		panic_error("tried to map to zero!")
	end if

	'' is one of the addresses not 4k-aligned?
	if ((cuint(v_addr) and &hFFF) or (cuint(physical) and &hFFF)) then return false

	'' do the flags try to manipulate the address?
	if (flags and VMM_PAGE_MASK) then return false

	'' page table not present?
	if ((*pagedir_entry_ptr and VMM_PDE_FLAGS.PRESENT) <> VMM_PDE_FLAGS.PRESENT) then
		'' reserve memory
		dim pagetable as any ptr = pmm_alloc()

		'' insert the new pagetable into the pagedir
		*pagedir_entry_ptr = cuint(pagetable) or (VMM_PDE_FLAGS.PRESENT or VMM_PDE_FLAGS.WRITABLE or VMM_PDE_FLAGS.USERSPACE)

		'' set the clear flag because the table is new, we cannot clear it now because it's not mapped
		clear_pagetable = true

		if (v_addr < &h40000000) then
			cntxt->version = latest_context->version+1
			latest_context = cntxt
		end if
	end if

	'' fetch page-table address from page directory
	dim page_table as uinteger ptr = get_pagetable(cntxt, GET_PAGEDIR_INDEX(v_addr))

	if (clear_pagetable) then
		'' if the table needs to be cleared we clear it now because it is now mapped
		memset(page_table, 0, PAGE_SIZE)
	end if

	'' set address and flags
	page_table[GET_PAGETABLE_INDEX(v_addr)] = (cuint(physical) or flags)

	'' invalidate virtual address
	asm
		mov ebx, dword ptr [v_addr]
		invlpg [ebx]
	end asm

	'' don't forget to free the pagetable
	free_pagetable(cntxt, page_table)

	return true
end function

sub vmm_unmap_page (cntxt as vmm_context ptr, v_addr as any ptr)
	vmm_map_page(cntxt, v_addr, nullptr, 0)
end sub

function vmm_map_range (cntxt as vmm_context ptr, v_addr as any ptr, p_start as any ptr, p_end as any ptr, flags as uinteger) as boolean
	dim v_dest as uinteger = cuint(v_addr) and VMM_PAGE_MASK
	dim p_src as uinteger = cuint(p_start) and VMM_PAGE_MASK


	'' FIXME: first check if the area is free, and map only then

	while (p_src < p_end)
		if ((vmm_map_page(cntxt, cast(any ptr, v_dest), cast(any ptr, p_src), flags)=0)) then
			return false
		end if
		p_src += PAGE_SIZE
		v_dest += PAGE_SIZE
	wend

	return true
end function

sub vmm_unmap_range (cntxt as vmm_context ptr, v_addr as any ptr, pages as uinteger)
	for counter as uinteger = 0 to pages-1
		vmm_unmap_page(cntxt, v_addr+counter*PAGE_SIZE)
	next
end sub

function get_pagetable (cntxt as vmm_context ptr, index as uinteger) as uinteger ptr
	dim pdir as uinteger ptr = iif(paging_activated, cntxt->v_pagedir, cntxt->p_pagedir)

	'' is there no pagetable?
	if ((pdir[index] and VMM_PTE_FLAGS.PRESENT) = 0) then return nullptr

	if (cntxt = current_context) then
		'' the pdir is currently active
		if (paging_activated) then
			return cast(uinteger ptr, VMM_PAGETABLES_VIRT_START + 4096*index)
		else
			return cast(uinteger ptr, pdir[index] and VMM_PAGE_MASK)
		end if
	else
		return vmm_kernel_automap(cast(any ptr, (pdir[index] and VMM_PAGE_MASK)), PAGE_SIZE)
	end if
end function

sub free_pagetable (cntxt as vmm_context ptr, table as uinteger ptr)
	if (cntxt <> current_context) then
		vmm_unmap_page(current_context, table)
	end if
end sub

function find_free_pages (cntxt as vmm_context ptr, pages as uinteger, lower_limit as uinteger, upper_limit as uinteger) as uinteger
	dim pdir as uinteger ptr = cntxt->v_pagedir
	dim free_pages_found as uinteger = 0

	dim cur_page_table as uinteger = lower_limit shr 22
	dim cur_page as uinteger = (lower_limit shr 12) mod 1024

	while ((free_pages_found < pages) and ((cur_page_table shl 22) < upper_limit))
		if (pdir[cur_page_table] and VMM_PTE_FLAGS.PRESENT) then
			'' ok, there is a page table, search the entries
			dim ptable as uinteger ptr = get_pagetable(cntxt, cur_page_table)

			while (cur_page < 1024)
				''is the entry free?
				if ((ptable[cur_page] and VMM_PTE_FLAGS.PRESENT) = 0) then
					free_pages_found += 1
					if (free_pages_found >= pages) then exit while
				else

					free_pages_found = 0
					lower_limit = (cur_page_table shl 22) or ((cur_page+1) shl 12)
				end if
				cur_page += 1
			wend

			free_pagetable(cntxt, ptable)
		else
			'' the whole table is free
			free_pages_found += 1024
		end if

		cur_page = 0
		cur_page_table += 1
	wend

	if ((free_pages_found >= pages) and (lower_limit + pages * PAGE_SIZE <= upper_limit)) then
		return lower_limit
	else
		return 0
	end if
end function

function vmm_automap (context as vmm_context ptr, p_start as any ptr, size as uinteger, lowerLimit as uinteger, upperLimit as uinteger, flags as uinteger) as any ptr
	if (size=0) then return 0

	dim aligned_addr as uinteger = cuint(p_start) and VMM_PAGE_MASK
	dim aligned_bytes as uinteger = size + (cuint(p_start) - aligned_addr)

	'' search for free pages
	dim vaddr as uinteger = find_free_pages(context, num_pages(aligned_bytes), lowerLimit, upperLimit)

	'' not enough free pages found?
	if (vaddr = 0) then return 0

	'' map the pages
	vmm_map_range(context, cast(any ptr, vaddr), cast(any ptr, aligned_addr), cast(any ptr, aligned_addr+aligned_bytes), flags)

	'' return the virtual address
	return vaddr + (p_start - aligned_addr)
end function

function vmm_kernel_automap (p_start as any ptr, size as uinteger, flags as uinteger = VMM_FLAGS.KERNEL_DATA) as any ptr
	return vmm_automap(vmm_get_current_context(), p_start, size, PAGE_SIZE, &h40000000, flags)
end function

sub vmm_kernel_unmap (v_start as any ptr, size as uinteger)
	vmm_unmap_range(vmm_get_current_context(), v_start, num_pages(size))
end sub

function vmm_resolve (cntxt as vmm_context ptr, vaddr as any ptr) as any ptr
	dim pagetable_virt as uinteger ptr
	dim result as uinteger

	'' get the pagetable
	pagetable_virt = get_pagetable(cntxt, GET_PAGEDIR_INDEX(cuint(vaddr)))

	'' pagetable not present?
	if (pagetable_virt = 0) then return 0

	'' get the entry of the page
	result = pagetable_virt[GET_PAGETABLE_INDEX(cuint(vaddr))]

	if (result and VMM_PTE_FLAGS.PRESENT) then
		'' page present
		result = (result and VMM_PAGE_MASK) or (cuint(vaddr) and &hFFF)
	else
		'' page not present
		result = 0
	end if

	'' free the pagetable
	free_pagetable(cntxt, pagetable_virt)

	return cast(any ptr, result)
end function

sub sync_context (cntxt as vmm_context ptr)
	if (cntxt->version < latest_context->version) then
		memcpy(cntxt->v_pagedir, latest_context->v_pagedir, &h3FC)
		cntxt->version = latest_context->version
	end if

	latest_context = cntxt
end sub

'' activates a vmm context by putting the pagedir address into cr3
sub vmm_activate_context (cntxt as vmm_context ptr)
	sync_context(cntxt)
	current_context = cntxt

	dim pagedir as uinteger ptr = cntxt->p_pagedir
	asm
		mov ebx, [pagedir]
		mov cr3, ebx
	end asm
end sub

function vmm_get_current_context () as vmm_context ptr
	return current_context
end function

function vmm_is_paging_activated () as boolean
	return paging_activated
end function

function vmm_is_paging_ready () as boolean
	return paging_ready
end function
