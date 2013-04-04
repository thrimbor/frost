#pragma once

#include "kernel.bi"

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
		FRAME         = &hFFFFF000
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
		FRAME         = &hFFFFF000
	end enum
    
    '' the kernels address space is from 0-1 gb, so we put the kernels pagetables at 1gb-4mb
    const PAGETABLES_VIRT_START as uinteger = &h3FC00000
    
    #define GET_PAGEDIR_INDEX(x) ((x shr 22) and &h3FF)
    #define GET_PAGETABLE_INDEX(x) ((x shr 12) and &h3FF)
    
    type context
		version as uinteger         '' important to keep the kernel section up to date
		p_pagedir as uinteger ptr   '' physical address of the pagedir
		v_pagedir as uinteger ptr   '' virtual address of the pagedir
	end type
    
    declare sub init ()
    declare function alloc (v_addr as any ptr) as boolean
    'declare function alloc() as any ptr
    declare sub context_initialize (cntxt as context ptr)
    declare function map_page (cntxt as context ptr, virtual as any ptr, physical as any ptr, flags as uinteger) as boolean
    declare function map_range (cntxt as context ptr, v_addr as any ptr, p_start as any ptr, p_end as any ptr, flags as uinteger) as boolean
    declare function kernel_automap (p_start as any ptr, size as uinteger) as any ptr
    declare sub activate_context (cntxt as context ptr)
    declare sub activate ()
    declare function get_current_pagedir () as uinteger ptr
end namespace
