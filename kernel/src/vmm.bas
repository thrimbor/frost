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

#include "vmm.bi"
#include "pmm.bi"
#include "kmm.bi"
#include "mem.bi"
#include "kernel.bi"
#include "panic.bi"

namespace vmm
	#define GET_PAGEDIR_INDEX(x) ((cuint(x) shr 22) and &h3FF)
    #define GET_PAGETABLE_INDEX(x) ((cuint(x) shr 12) and &h3FF)
	
	declare function get_pagetable (cntxt as context ptr, index as uinteger) as uinteger ptr
	declare sub free_pagetable (cntxt as context ptr, table as uinteger ptr)
	declare sub sync_context (cntxt as context ptr)
	declare sub activate ()
	
    dim shared kernel_context as context
    dim shared current_context as context ptr
    dim shared paging_activated as byte = 0
    
    dim shared latest_pagedir_version as uinteger = 0
    dim shared latest_pagedir as uinteger ptr = 0
    
    '' sets up the required structures and activates paging
    sub init ()
        '' initialize the kernel context (only used before the first task is started)
        '' the pagedir is also automatically mapped
        kernel_context.version = -1
        kernel_context.p_pagedir = pmm.alloc()
        memset(kernel_context.p_pagedir, 0, pmm.PAGE_SIZE)
        kernel_context.v_pagedir = kernel_context.p_pagedir
        
        '' we need to activate the context early for kernel_context to be valid
        activate_context(@kernel_context)
        
        '' map the page tables
        kernel_context.p_pagedir[PAGETABLES_VIRT_START shr 22] = cuint(kernel_context.p_pagedir) or PTE_FLAGS.PRESENT or PTE_FLAGS.WRITABLE
        
        '' map the kernel 1:1
        map_range(@kernel_context, kernel_start, kernel_start, kernel_end, (PTE_FLAGS.PRESENT or PTE_FLAGS.WRITABLE))
        
        '' map the video memory 1:1
        map_page(@kernel_context, cast(any ptr, &hB8000), cast(any ptr, &hB8000), (PTE_FLAGS.PRESENT or PTE_FLAGS.WRITABLE))
        
        '' set the virtual address
        kernel_context.v_pagedir = cast(uinteger ptr, (PAGETABLES_VIRT_START shr 22)*4096*1024 + (PAGETABLES_VIRT_START shr 22)*4096)
        
        latest_pagedir = kernel_context.v_pagedir
        latest_pagedir_version = 1
        
        '' activate paging
        activate()
        
        paging_activated = -1
    end sub
    
    '' reserve a page and map it
    function alloc (v_addr as any ptr) as boolean
		'' allocate a page
		dim page as any ptr = pmm.alloc()
		
		'' unsuccessful? return false
		if (page = nullptr) then return false
		
		'' try to map it where we need it
		if (not(map_page(current_context, v_addr, page, (PTE_FLAGS.PRESENT or PTE_FLAGS.WRITABLE)))) then
			pmm.free(page)
			return false
		end if
		
		return true
	end function
   
    '' create_context () creates and clears space for a page-directory
    sub context_initialize (cntxt as context ptr)
        cntxt->version = 0
        cntxt->p_pagedir = pmm.alloc()
        cntxt->v_pagedir = kernel_automap(cntxt->p_pagedir, pmm.PAGE_SIZE)
        memset(cntxt->v_pagedir, 0, pmm.PAGE_SIZE)
        
        '' copy the kernel address space
        sync_context(cntxt)
        
        '' pagetables need to be accessible
        cntxt->v_pagedir[PAGETABLES_VIRT_START shr 22] = cuint(cntxt->p_pagedir) or PTE_FLAGS.PRESENT or PTE_FLAGS.WRITABLE
    end sub
    
    '' map_page maps a single page into a given context
    function map_page (cntxt as context ptr, v_addr as any ptr, physical as any ptr, flags as uinteger) as boolean
        '' memorize if the pagetable needs to be cleared (needed when we allocate a new pagetable)
        dim clear_pagetable as boolean = false
        '' the entry in the pagedir
        dim pagedir_entry_ptr as uinteger ptr = @(cntxt->v_pagedir[GET_PAGEDIR_INDEX(v_addr)])
        
        '// multiline if because of the multiline macro - we would get strange errors otherwise
        if (v_addr = 0) then
			panic_error("tried to map to zero!")
		end if
		
        '' is one of the addresses not 4k-aligned?
        if ((cuint(v_addr) and &hFFF) or (cuint(physical) and &hFFF)) then return false
        
        '' do the flags try to manipulate the address?
        if (flags and PAGE_MASK) then return false
        
        '' page table not present?
        if ((*pagedir_entry_ptr and PDE_FLAGS.PRESENT) <> PDE_FLAGS.PRESENT) then
            '' reserve memory
            dim pagetable as any ptr = pmm.alloc()
            
            '' insert the new pagetable into the pagedir
            *pagedir_entry_ptr = cuint(pagetable) or (PDE_FLAGS.PRESENT or PDE_FLAGS.WRITABLE or PDE_FLAGS.USERSPACE)
            
            '' set the clear flag because the table is new, we cannot clear it now because it's not mapped
            clear_pagetable = true
        end if
        
        '' fetch page-table address from page directory
		dim page_table as uinteger ptr = get_pagetable(cntxt, GET_PAGEDIR_INDEX(v_addr))
		
		if (clear_pagetable) then
			'' if the table needs to be cleared we clear it now because it is now mapped
			memset(page_table, 0, pmm.PAGE_SIZE)
		end if
        
        '' set address and flags
        page_table[GET_PAGETABLE_INDEX(v_addr)] = (cuint(physical) or flags)
		
        '' invalidate virtual address
        asm
			mov eax, dword ptr [v_addr]
			invlpg [eax]
		end asm
		
		cntxt->version = latest_pagedir_version+1
		latest_pagedir = cntxt->v_pagedir
        
        '' don't forget to free the pagetable
        free_pagetable(cntxt, page_table)
        
        return true
    end function
    
    sub unmap_page (cntxt as context ptr, v_addr as any ptr)
		map_page(cntxt, v_addr, nullptr, 0)
	end sub
    
    function map_range (cntxt as context ptr, v_addr as any ptr, p_start as any ptr, p_end as any ptr, flags as uinteger) as boolean
        dim v_dest as uinteger = cuint(v_addr) and PAGE_MASK
        dim p_src as uinteger = cuint(p_start) and PAGE_MASK
        
        
		'' FIXME: first check if the area is free, and map only then
        
        while (p_src < p_end)
            if ((map_page(cntxt, cast(any ptr, v_dest), cast(any ptr, p_src), flags)=0)) then
                return false
            end if
            p_src += pmm.PAGE_SIZE
            v_dest += pmm.PAGE_SIZE
        wend
        
        return true
    end function
    
    sub unmap_range (cntxt as context ptr, v_addr as any ptr, num_pages as uinteger)
		for counter as uinteger = 0 to num_pages
			unmap_page(cntxt, v_addr+counter*pmm.PAGE_SIZE)
		next
	end sub
	
	function get_pagetable (cntxt as context ptr, index as uinteger) as uinteger ptr
		dim pdir as uinteger ptr = cntxt->v_pagedir
		
		'' is there no pagetable?
		if ((pdir[index] and PTE_FLAGS.PRESENT) = 0) then return nullptr
		
		if (cntxt = current_context) then
			'' the pdir is currently active
			if (paging_activated) then
				return cast(uinteger ptr, PAGETABLES_VIRT_START + 4096*index)
			else
				return cast(uinteger ptr, pdir[index] and PAGE_MASK)
			end if
		else
			return kernel_automap(cast(any ptr, (pdir[index] and PAGE_MASK)), pmm.PAGE_SIZE)
		end if
	end function
	
	sub free_pagetable (cntxt as context ptr, table as uinteger ptr)
		if (cntxt <> current_context) then
			unmap_page(current_context, table)
		end if
	end sub
	
	function find_free_pages (cntxt as context ptr, num_pages as uinteger) as uinteger
		dim pdir as uinteger ptr = cntxt->v_pagedir
		dim free_pages_found as uinteger = 0
		dim lower_limit as uinteger = pmm.PAGE_SIZE
		dim upper_limit as uinteger = &h40000000
		
		dim cur_page_table as uinteger = lower_limit shr 22
		dim cur_page as uinteger = (lower_limit shr 12) mod 1024
		
		while ((free_pages_found < num_pages) and ((cur_page_table shl 22) < upper_limit))
			if (pdir[cur_page_table] and PTE_FLAGS.PRESENT) then
				'' ok, there is a page table, search the entries
				dim ptable as uinteger ptr = get_pagetable(cntxt, cur_page_table)
				
				while (cur_page < 1024)
					''is the entry free?
					if ((ptable[cur_page] and PTE_FLAGS.PRESENT) = 0) then
						free_pages_found += 1
						if (free_pages_found >= num_pages) then exit while
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
		
		if ((free_pages_found >= num_pages) and (lower_limit + num_pages * pmm.PAGE_SIZE <= upper_limit)) then
			return lower_limit
		else
			return 0
		end if
	end function

	function kernel_automap (p_start as any ptr, size as uinteger) as any ptr
		'' this maps a piece of physical memory to a free location in the kernel's address space
		'' and returns the virtual address
		if (size = 0) then return 0
		dim aligned_addr as uinteger = cuint(p_start) and PAGE_MASK
		dim aligned_bytes as uinteger = size + (cuint(p_start) - aligned_addr)
		dim cntxt as context ptr = get_current_context()
		
		dim vaddr as uinteger = find_free_pages(cntxt, num_pages(aligned_bytes))
		if (vaddr = 0) then
			'' we have a problem, we could not find enough space
			return 0
		end if
		
		map_range(cntxt, cast(any ptr, vaddr), cast(any ptr, aligned_addr), cast(any ptr, aligned_addr+aligned_bytes), PTE_FLAGS.PRESENT or PTE_FLAGS.WRITABLE)
		return vaddr + (p_start - aligned_addr)
	end function
	
	sub kernel_unmap (v_start as any ptr, size as uinteger)
		unmap_range(get_current_context(), v_start, num_pages(size))
	end sub
	
	function resolve (cntxt as context ptr, vaddr as any ptr) as any ptr
		dim pagetable_virt as uinteger ptr 
		dim result as uinteger
		
		'' get the pagetable
		pagetable_virt = get_pagetable(cntxt, GET_PAGEDIR_INDEX(cuint(vaddr)))
		
		'' pagetable not present?
		if (pagetable_virt = 0) then return 0
		
		'' get the entry of the page
		result = pagetable_virt[GET_PAGETABLE_INDEX(cuint(vaddr))]
		
		if (result and PTE_FLAGS.PRESENT) then
			'' page present
			result = (result and PAGE_MASK) or (cuint(vaddr) and &hFFF)
		else
			'' page not present
			result = 0
		end if
		
		'' free the pagetable
		free_pagetable(cntxt, pagetable_virt)
		
		return cast(any ptr, result)
	end function
	
	sub sync_context (cntxt as context ptr)
		if (cntxt->version < latest_pagedir_version) then
			memcpy(cntxt->v_pagedir, latest_pagedir, 1020)
			cntxt->version = latest_pagedir_version
		end if
		
		latest_pagedir = cntxt->v_pagedir
	end sub
    
    '' activates a vmm context by putting the pagedir address into cr3
    sub activate_context (cntxt as context ptr)
        sync_context(cntxt)
        current_context = cntxt
        dim pagedir as uinteger ptr = cntxt->p_pagedir
        asm
            mov eax, [pagedir]
            mov cr3, eax
        end asm
    end sub
    
    function get_current_context () as context ptr
		return current_context
	end function
    
    '' activates paging by setting the paging-bit (31) in cr0
    sub activate ()
        asm
            mov eax, cr0
            or eax, &h80000000
            mov cr0, eax
        end asm
    end sub
end namespace
