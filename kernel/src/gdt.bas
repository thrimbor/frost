#include "kernel.bi"
#include "gdt.bi"
#include "video.bi"


namespace gdt
    dim shared descriptor as gdt.table_descriptor
    dim shared table (0 to gdt.TABLE_SIZE) as gdt.segment_descriptor
    dim tss (0 to 31) as uinteger
    
    
    '' this sub initializes the GDT with Code- and Data-Segments for Ring 0 and Ring 3.
    '' it also does basic tss-setup
    sub prepare ()
        tss_ptr = @tss(0) '' initialize the tss-pointer (used in other parts of the kernel)
        tss(2) = &h10     '' set the ss0-entry (kernel stack segment) of the tss
        
        '' first the RING-0 Code-Segment
        gdt.set_entry(1, 0, &hFFFFF, (FLAG_PRESENT or FLAG_PRIVILEGE_RING_0 or FLAG_SEGMENT or FLAG_EXECUTABLE or FLAG_RW), (FLAG_GRANULARITY or FLAG_SIZE))
        
        '' now the RING-0 Data-Segment
        gdt.set_entry(2, 0, &hFFFFF, (FLAG_PRESENT or FLAG_PRIVILEGE_RING_0 or FLAG_SEGMENT or FLAG_RW), (FLAG_GRANULARITY or FLAG_SIZE))
        
        '' the RING-3 Code-Segment
        gdt.set_entry(3, 0, &hFFFFF, (FLAG_PRESENT or FLAG_PRIVILEGE_RING_3 or FLAG_SEGMENT or FLAG_EXECUTABLE or FLAG_RW), (FLAG_GRANULARITY or FLAG_SIZE))
        
        '' the RING-3 Data-Segment
        gdt.set_entry(4, 0, &hFFFFF, (FLAG_PRESENT or FLAG_PRIVILEGE_RING_3 or FLAG_SEGMENT or FLAG_RW), (FLAG_GRANULARITY or FLAG_SIZE))
        
        '' the tss
        gdt.set_entry(5, cuint(tss_ptr), 32*4, (FLAG_PRESENT or FLAG_PRIVILEGE_RING_3 or FLAG_TSS), 0)
             
        gdt.descriptor.limit = (gdt.TABLE_SIZE+1)*8-1 '' calculate the size of the entries + null-entry
        gdt.descriptor.start  = cuint(@gdt.table(0))   '' set the address of the table
    end sub
    
    sub load ()
		'' load the gdt
		asm lgdt [gdt.descriptor]
        
        '' refresh the segment registers, so the gdt is really being used
        asm
            mov ax, &h10
            mov ds, ax
            mov es, ax
            mov fs, ax
            mov gs, ax
            mov ss, ax
            ljmp &h08:gdt_jmp
            gdt_jmp:
        end asm
        
        '' load the task-register
        asm
            mov ax, &h28
            ltr ax
        end asm
	end sub
    
    '' this sub is just a helper function to provide easier access to the GDT.
    '' it puts the passed arguments in the right place of a GDT-entry.
    sub set_entry (index as ushort, start as uinteger, limit as uinteger, accessbyte as ubyte, flags as ubyte)
        gdt.table(index).limit_low      = loword(limit)
        gdt.table(index).start_low      = loword(start)
        gdt.table(index).start_middle   = lobyte(hiword(start))
        gdt.table(index).accessbyte     = accessbyte
        gdt.table(index).flags_limit2   = (lobyte(hiword(limit)) and &h0F)
        gdt.table(index).flags_limit2 or= ((flags shl 4) and &hF0)
        gdt.table(index).start_high     = hibyte(hiword(start))
    end sub
end namespace
