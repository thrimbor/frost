namespace paging
    const FLAG_PRESENT   as uinteger = &b1
    const FLAG_WRITE     as uinteger = &b10
    const FLAG_USERSPACE as uinteger = &b100
    
    declare sub init ()
    declare function map_page (page_directory as uinteger ptr, virtual as uinteger, physical as uinteger, flags as uinteger) as byte
    declare function get_p_addr (page_directory as uinteger ptr, v_addr as uinteger, reserve_if_na as ubyte) as uinteger
    declare sub copy_to_context (page_directory as uinteger ptr, p_start as uinteger, v_dest as uinteger, size as uinteger)
    declare sub activate_directory (page_directory as uinteger ptr)
    declare sub activate ()
end namespace