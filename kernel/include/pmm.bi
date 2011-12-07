#include once "kernel.bi"
#include once "multiboot.bi"

namespace pmm
    '' we have 4KB per bit, so we need a map for 32k*32bits for 4GB
    const bitmap_size = 32768
    const PAGE_SIZE = 4096
    
    declare sub init (mbinfo as multiboot_info ptr)
    declare function alloc () as any ptr
    declare sub free (page as any ptr)
    declare sub mark_used (page as any ptr)
    declare function get_total () as uinteger
    declare function get_free () as uinteger
end namespace
