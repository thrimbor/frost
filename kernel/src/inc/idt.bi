namespace idt
    type table_descriptor field=1
        limit as ushort
        base  as uinteger
    end type
    
    type gate_descriptor field=1
        offset_low as ushort
        selector as ushort
        reserved as ubyte
        accessbyte as ubyte
        offset_high as ushort
    end type
    
    const table_size = &h63
    
    '// flags for the access-byte
    const FLAG_PRESENT           as ubyte = &h80
    const FLAG_PRIVILEGE_RING_3  as ubyte = &h60
    const FLAG_PRIVILEGE_RING_2  as ubyte = &h40
    const FLAG_PRIVILEGE_RING_1  as ubyte = &h20
    const FLAG_PRIVILEGE_RING_0  as ubyte = &h00
    const FLAG_SEGMENT           as ubyte = &h10
    const FLAG_TASK_GATE         as ubyte = &h05
    const FLAG_INTERRUPT_GATE_16 as ubyte = &h06
    const FLAG_INTERRUPT_GATE_32 as ubyte = &h0E
    const FLAG_TRAP_GATE_16      as ubyte = &h07
    const FLAG_TRAP_GATE_32      as ubyte = &h0F
    
    declare sub init ()
    declare sub set_entry (i as ushort, offset as uinteger, selector as ushort, accessbyte as ubyte)
end namespace
