const HEAP_MAGIC as uinteger = &hDEADBEEF

type kmm_header field = 1
    magic as uinteger             '' magic number to identify blocks
    is_hole as ubyte              '' true if this is a hole, false if this is a block
    size as uinteger              '' size of the "content-area" of the block
end type

type kmm_content field = 1
    prev_entry as kmm_header ptr  '' pointer to the previous entry in the linked list
    next_entry as kmm_header ptr  '' pointer to the next entry in the linked list
end type

type kmm_footer field = 1
    magic as uinteger             '' magic number to identify footers
    header as kmm_header ptr      '' pointer to the block-header
end type

declare sub kmm_init (start_addr as uinteger, end_addr as uinteger, minimum as uinteger, maximum as uinteger)
declare function kmalloc (size as uinteger) as any ptr
declare sub kfree (addr as any ptr)
