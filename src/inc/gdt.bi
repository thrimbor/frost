namespace gdt
    type table_descriptor field=1
        limit as ushort
        base as uinteger
    end type
    
    type segment_descriptor field=1
        limit1 as ubyte
        limit2 as ubyte
        base1  as ubyte
        base2  as ubyte
        base3  as ubyte
        accessbyte as ubyte
        flags_limit3  as ubyte
        base4  as ubyte
    end type
    
    const table_size = 4
    
    '// flags for the access-byte
    const FLAG_PRESENT_BIT      as ubyte = &h80  '// must be 1 for an active entry
    const FLAG_PRIVILEGE_RING_3 as ubyte = &h60
    const FLAG_PRIVILEGE_RING_2 as ubyte = &h40
    const FLAG_PRIVILEGE_RING_1 as ubyte = &h20
    const FLAG_PRIVILEGE_RING_0 as ubyte = &h00
    const FLAG_SEGMENT_BIT      as ubyte = &h10  '// 1 for Code-/Data-segments, 0 for gates and TSS
    const FLAG_EXECUTABLE_BIT   as ubyte = &h08  '// unset = DS, set = CS
    const FLAG_DC_BIT           as ubyte = &h04
    const FLAG_RW_BIT           as ubyte = &h02  '// CS: read access, DS: write access
    const FLAG_ACCESSED_BIT     as ubyte = &h01  '// set by CPU. DO NOT USE!
    
    '// flags for the flags-byte
    const FLAG_GRANULARITY_BIT as ubyte = &h08 '// if set, size is in 4KB units
    const FLAG_SIZE_BIT        as ubyte = &h04 '// unset = 16 bit PM, set = 32 bit PM
    const FLAG_LONG_MODE_BIT   as ubyte = &h02 '// if set, it's a long mode segment
    const FLAG_AVAILABLE_BIT   as ubyte = &h01 '// free bit
    
    declare sub init ()
    declare sub set_entry (i as ushort, base as uinteger, limit as uinteger, access as ubyte, flags as ubyte)
end namespace
