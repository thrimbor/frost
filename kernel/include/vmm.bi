#pragma once

namespace vmm
    const FLAG_PRESENT   as uinteger = &b1
    const FLAG_WRITE     as uinteger = &b10
    const FLAG_USERSPACE as uinteger = &b100
    
    type context as uinteger ptr
    
    declare sub init ()
    declare function alloc() as any ptr
    declare function create_context () as context
    declare function map_page (page_directory as context, virtual as uinteger, physical as uinteger, flags as uinteger) as integer
    declare function map_range (page_directory as context, v_addr as uinteger, p_start as uinteger, p_end as uinteger, flags as uinteger) as integer
    declare function get_p_addr (page_directory as context, v_addr as uinteger, reserve_if_na as ubyte) as uinteger
    declare sub copy_to_context (page_directory as context, p_start as uinteger, v_dest as uinteger, size as uinteger)
    declare sub activate_context (page_directory as context)
    declare sub activate ()
end namespace
