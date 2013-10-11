/'
 ' FROST x86 microkernel
 ' Copyright (C) 2010-2013  Stefan Schmidt
 ' 
 ' This program is free software: you can redistribute it and/or modify
 ' it under the terms of the GNU General Public License as published by
 ' the Free Software Foundation, either version 3 of the License, or
 ' (at your option) any later version.
 ' 
 ' This program is distributed in the hope that it will be useful,
 ' but WITHOUT ANY WARRANTY; without even the implied warranty of
 ' MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 ' GNU General Public License for more details.
 ' 
 ' You should have received a copy of the GNU General Public License
 ' along with this program.  If not, see <http://www.gnu.org/licenses/>.
 '/

#include "kernel.bi"
#include "gdt.bi"
#include "video.bi"


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
    
    const TABLE_SIZE = 5
    
    declare sub set_entry (i as ushort, start as uinteger, limit as uinteger, access as ubyte, flags as ubyte)

    dim shared descriptor as gdt.table_descriptor
    dim shared table (0 to gdt.TABLE_SIZE) as gdt.segment_descriptor
    'dim tss (0 to 31) as uinteger
    dim tss as task_state_segment
    
    
    '' this sub initializes the GDT with Code- and Data-Segments for Ring 0 and Ring 3.
    '' it also does basic tss-setup
    sub prepare ()
        tss_ptr = @tss     '' initialize the tss-pointer (used in other parts of the kernel)
        tss.ss0 = &h10     '' set the kernel stack segment of the tss
        tss.io_bitmap_offset = TSS_IO_BITMAP_NOT_LOADED
        
        '' RING-0 Code-Segment
        gdt.set_entry(1, 0, &hFFFFF, (FLAG_PRESENT or FLAG_PRIVILEGE_RING_0 or FLAG_SEGMENT or FLAG_EXECUTABLE or FLAG_RW), (FLAG_GRANULARITY or FLAG_SIZE))
        
        '' RING-0 Data-Segment
        gdt.set_entry(2, 0, &hFFFFF, (FLAG_PRESENT or FLAG_PRIVILEGE_RING_0 or FLAG_SEGMENT or FLAG_RW), (FLAG_GRANULARITY or FLAG_SIZE))
        
        '' RING-3 Code-Segment
        gdt.set_entry(3, 0, &hFFFFF, (FLAG_PRESENT or FLAG_PRIVILEGE_RING_3 or FLAG_SEGMENT or FLAG_EXECUTABLE or FLAG_RW), (FLAG_GRANULARITY or FLAG_SIZE))
        
        '' RING-3 Data-Segment
        gdt.set_entry(4, 0, &hFFFFF, (FLAG_PRESENT or FLAG_PRIVILEGE_RING_3 or FLAG_SEGMENT or FLAG_RW), (FLAG_GRANULARITY or FLAG_SIZE))
        
        '' TSS
        gdt.set_entry(5, cuint(tss_ptr), sizeof(task_state_segment), (FLAG_PRESENT or FLAG_PRIVILEGE_RING_3 or FLAG_TSS), 0)
             
        gdt.descriptor.limit = (gdt.TABLE_SIZE+1)*8-1 '' calculate the size of the entries + null-entry
        gdt.descriptor.start  = cuint(@gdt.table(0))  '' set the address of the table
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
