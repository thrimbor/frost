type kmm_block_header field = 1
    magic as uinteger
    is_hole as ubyte
    size as uinteger
end type

type kmm_block_content_area field = 1
    prev_entry as kmm_block_header ptr
    next_entry as kmm_block_header ptr
end type

type kmm_block_footer field = 1
    magic as uinteger
    header as kmm_block_header ptr
end type

declare sub memcpy (destination as any ptr, source as any ptr, size as uinteger)
declare sub memset (destination as any ptr, value as ubyte, size as uinteger)
declare function kmalloc (size as uinteger) as any ptr
declare sub kfree (addr as any ptr)
