type kmm_block_header
    magic as uinteger
    is_hole as ubyte
    size as uinteger
end type

type kmm_block_footer
    magic as uinteger
    header as kmm_block_header ptr
end type

declare sub memcpy (destination as any ptr, source as any ptr, size as uinteger)
declare sub memset (destination as any ptr, value as ubyte, size as uinteger)
declare function malloc (size as uinteger) as any ptr
declare sub free (addr as any ptr)
