#pragma once

namespace vmm
    const FLAG_PRESENT   as uinteger = &b1
    const FLAG_WRITE     as uinteger = &b10
    const FLAG_USERSPACE as uinteger = &b100
    
    '' the kernel's address space is from 0-1 gb, so we put the pagetables at 1gb-4mb
    const PAGETABLES_VIRT_START as uinteger = &h3FC00000
    
    type context
		version as uinteger
		pagedir as uinteger ptr
		v_pagedir as uinteger ptr
	end type
    
    declare sub init ()
    declare function alloc() as any ptr
    declare sub context_initialize (cntxt as context ptr)
    declare function map_page (cntxt as context ptr, virtual as uinteger, physical as uinteger, flags as uinteger) as integer
    declare function map_range (cntxt as context ptr, v_addr as uinteger, p_start as uinteger, p_end as uinteger, flags as uinteger) as integer
    declare function kernel_automap (p_start as any ptr, size as uinteger) as any ptr
    declare function get_p_addr (cntxt as context ptr, v_addr as uinteger, reserve_if_na as ubyte) as uinteger
    declare sub activate_context (cntxt as context ptr)
    declare sub activate ()
    declare function get_current_pagedir () as uinteger ptr
end namespace
