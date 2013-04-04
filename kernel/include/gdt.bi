#pragma once

namespace gdt
    type table_descriptor field=1
        limit as ushort
        start  as uinteger
    end type
    
    type segment_descriptor field=1
        limit_low    as ushort
        start_low     as ushort
        start_middle  as ubyte
        accessbyte   as ubyte
        flags_limit2 as ubyte
        start_high    as ubyte
    end type
    
    const TABLE_SIZE = 5
    
    '' flags for the access-byte
    const FLAG_PRESENT          as ubyte = &h80  '' must be set for an active entry
    const FLAG_PRIVILEGE_RING_3 as ubyte = &h60
    const FLAG_PRIVILEGE_RING_2 as ubyte = &h40
    const FLAG_PRIVILEGE_RING_1 as ubyte = &h20
    const FLAG_PRIVILEGE_RING_0 as ubyte = &h00
    const FLAG_SEGMENT          as ubyte = &h10  '' set for Code-/Data-segments, unset for gates and TSS
    const FLAG_EXECUTABLE       as ubyte = &h08  '' unset = DS, set = CS
    const FLAG_DC               as ubyte = &h04
    const FLAG_RW               as ubyte = &h02  '' CS: read access, DS: write access
    const FLAG_ACCESSED         as ubyte = &h01  '' set by CPU. DO NOT USE!
    const FLAG_TSS              as ubyte = &h09  '' tss is a bit special
    
    '' flags for the flags-byte
    const FLAG_GRANULARITY as ubyte = &h08 '' if set, size is in 4KB units
    const FLAG_SIZE        as ubyte = &h04 '' unset = 16 bit PM, set = 32 bit PM
    const FLAG_LONG_MODE   as ubyte = &h02 '' if set, it's a long mode segment
    const FLAG_AVAILABLE   as ubyte = &h01 '' free bit
    
    declare sub prepare ()
    declare sub load ()
    declare sub set_entry (i as ushort, start as uinteger, limit as uinteger, access as ubyte, flags as ubyte)
end namespace
