#include once "inc/idt.bi"

#include once "inc/video.bi"
sub testsub naked ()
    video.cout("A")
end sub

namespace idt
    dim shared idtp as idt.table_descriptor
    dim shared table (0 to idt.table_size-1) as idt.gate_descriptor
    
    sub init ()
        idt.set_entry (&h30, cuint(@testsub), &h08, (FLAG_PRESENT or FLAG_PRIVILEGE_RING_0 or FLAG_INTERRUPT_GATE_32))
        
        '// now we load the idt
        idt.idtp.limit = idt.table_size*8-1
        idt.idtp.base  = cuint(@idt.table(0))
        asm lidt [idt.idtp]
    end sub
    
    sub set_entry (i as ushort, offset as uinteger, selector as ushort, accessbyte as ubyte)
        idt.table(i).offset_low  = loword(offset)
        idt.table(i).offset_high = hiword(offset)
        idt.table(i).selector    = selector
        idt.table(i).reserved    = 0
        idt.table(i).accessbyte  = accessbyte
    end sub
end namespace
