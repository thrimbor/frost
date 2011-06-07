namespace paging
    const FLAG_PRESENT   as uinteger = &b1
    const FLAG_WRITE     as uinteger = &b10
    const FLAG_USERSPACE as uinteger = &b100
    
    declare sub init
    declare function map_page (page_directory as uinteger ptr, virtual as uinteger, physical as uinteger, flags as uinteger) as byte
    declare sub copy_into_context (page_directory as uinteger ptr, p_start as uinteger, size as uinteger, virtual as uinteger)
    declare sub activate_directory (page_directory as uinteger ptr)
    declare sub activate ()
end namespace