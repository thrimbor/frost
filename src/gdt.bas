#include once "inc/gdt.bi"

namespace gdt
    dim shared gdtp as gdt.table_descriptor
    dim shared table (0 to gdt.table_size) as gdt.segment_descriptor
    
    sub init ()
        '// first the RING-0 Code-Segment    
        gdt.set_entry(1, 0, &hFFFFF, (FLAG_PRESENT_BIT or FLAG_PRIVILEGE_RING_0 or FLAG_SEGMENT_BIT or FLAG_EXECUTABLE_BIT or FLAG_RW_BIT), (FLAG_GRANULARITY_BIT or FLAG_SIZE_BIT))
        '// now the RING-0 Data-Segment
        gdt.set_entry(2, 0, &hFFFFF, (FLAG_PRESENT_BIT or FLAG_PRIVILEGE_RING_0 or FLAG_SEGMENT_BIT or FLAG_RW_BIT), (FLAG_GRANULARITY_BIT or FLAG_SIZE_BIT))
        '// the RING-3 Code-Segment
        gdt.set_entry(3, 0, &hFFFFF, (FLAG_PRESENT_BIT or FLAG_PRIVILEGE_RING_3 or FLAG_SEGMENT_BIT or FLAG_EXECUTABLE_BIT or FLAG_RW_BIT), (FLAG_GRANULARITY_BIT or FLAG_SIZE_BIT))
        '// the RING-3 Data-Segment
        gdt.set_entry(4, 0, &hFFFFF, (FLAG_PRESENT_BIT or FLAG_PRIVILEGE_RING_0 or FLAG_SEGMENT_BIT or FLAG_RW_BIT), (FLAG_GRANULARITY_BIT or FLAG_SIZE_BIT))
        
        '// ok, fine so far, now we have to load the gdt
        '// calculate the size of the actual gdt (gdt + null-entry)        
        gdt.gdtp.limit = (gdt.table_size+1)*8-1
        gdt.gdtp.base = cast(uinteger, @gdt.table(0))
        asm
            lgdt [gdt.gdtp]
        end asm
        
        '// here has to come a refresh of the segment registers, otherwise the gdt won't be loaded!
        asm
            mov ax, &h10
            mov ds, ax
            mov es, ax
            mov fs, ax
            mov gs, ax
            mov ss, ax
            ljmp &h08, gdt_jmp
            gdt_jmp:
        end asm
    end sub
    
    sub set_entry (i as ushort, base as uinteger, limit as uinteger, accessbyte as ubyte, flags as ubyte)
        gdt.table(i).limit1 = lobyte(limit)
        gdt.table(i).limit2 = hibyte(limit)
        gdt.table(i).base1  = lobyte(base)
        gdt.table(i).base2  = hibyte(base)
        gdt.table(i).base3  = lobyte(hiword(base))
        gdt.table(i).accessbyte = accessbyte
        gdt.table(i).flags_limit3 = (lobyte(hiword(limit)) and &hF0)
        gdt.table(i).flags_limit3 or= (flags and &h0F)
        gdt.table(i).base4  = hibyte(hiword(base))
    end sub
end namespace
