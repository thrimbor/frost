#include "idt.bi"
#include "interrupt_handler.bi"

namespace idt
    dim shared descriptor as idt.table_descriptor
    dim shared table (0 to idt.TABLE_SIZE-1) as idt.gate_descriptor
    
    '' this sub sets up and loads an IDT for exceptions, IRQs and the syscall-interrupt.
    sub init ()
        '' register the handlers for the exceptions
        idt.set_entry (&h00, @int_stub_0, &h08, (FLAG_PRESENT or FLAG_PRIVILEGE_RING_0 or FLAG_INTERRUPT_GATE_32))
        idt.set_entry (&h01, @int_stub_1, &h08, (FLAG_PRESENT or FLAG_PRIVILEGE_RING_0 or FLAG_INTERRUPT_GATE_32))
        idt.set_entry (&h02, @int_stub_2, &h08, (FLAG_PRESENT or FLAG_PRIVILEGE_RING_0 or FLAG_INTERRUPT_GATE_32))
        idt.set_entry (&h03, @int_stub_3, &h08, (FLAG_PRESENT or FLAG_PRIVILEGE_RING_0 or FLAG_INTERRUPT_GATE_32))
        idt.set_entry (&h04, @int_stub_4, &h08, (FLAG_PRESENT or FLAG_PRIVILEGE_RING_0 or FLAG_INTERRUPT_GATE_32))
        idt.set_entry (&h05, @int_stub_5, &h08, (FLAG_PRESENT or FLAG_PRIVILEGE_RING_0 or FLAG_INTERRUPT_GATE_32))
        idt.set_entry (&h06, @int_stub_6, &h08, (FLAG_PRESENT or FLAG_PRIVILEGE_RING_0 or FLAG_INTERRUPT_GATE_32))
        idt.set_entry (&h07, @int_stub_7, &h08, (FLAG_PRESENT or FLAG_PRIVILEGE_RING_0 or FLAG_INTERRUPT_GATE_32))
        idt.set_entry (&h08, @int_stub_8, &h08, (FLAG_PRESENT or FLAG_PRIVILEGE_RING_0 or FLAG_INTERRUPT_GATE_32))
        idt.set_entry (&h09, @int_stub_9, &h08, (FLAG_PRESENT or FLAG_PRIVILEGE_RING_0 or FLAG_INTERRUPT_GATE_32))
        idt.set_entry (&h0A, @int_stub_10, &h08, (FLAG_PRESENT or FLAG_PRIVILEGE_RING_0 or FLAG_INTERRUPT_GATE_32))
        idt.set_entry (&h0B, @int_stub_11, &h08, (FLAG_PRESENT or FLAG_PRIVILEGE_RING_0 or FLAG_INTERRUPT_GATE_32))
        idt.set_entry (&h0C, @int_stub_12, &h08, (FLAG_PRESENT or FLAG_PRIVILEGE_RING_0 or FLAG_INTERRUPT_GATE_32))
        idt.set_entry (&h0D, @int_stub_13, &h08, (FLAG_PRESENT or FLAG_PRIVILEGE_RING_0 or FLAG_INTERRUPT_GATE_32))
        idt.set_entry (&h0E, @int_stub_14, &h08, (FLAG_PRESENT or FLAG_PRIVILEGE_RING_0 or FLAG_INTERRUPT_GATE_32))
        idt.set_entry (&h0F, @int_stub_15, &h08, (FLAG_PRESENT or FLAG_PRIVILEGE_RING_0 or FLAG_INTERRUPT_GATE_32))
        idt.set_entry (&h10, @int_stub_16, &h08, (FLAG_PRESENT or FLAG_PRIVILEGE_RING_0 or FLAG_INTERRUPT_GATE_32))
        idt.set_entry (&h11, @int_stub_17, &h08, (FLAG_PRESENT or FLAG_PRIVILEGE_RING_0 or FLAG_INTERRUPT_GATE_32))
        idt.set_entry (&h12, @int_stub_18, &h08, (FLAG_PRESENT or FLAG_PRIVILEGE_RING_0 or FLAG_INTERRUPT_GATE_32))
        '' 19-31 are reserved
        
        '' now the IRQ's
        idt.set_entry (&h20, @int_stub_32, &h08, (FLAG_PRESENT or FLAG_PRIVILEGE_RING_0 or FLAG_INTERRUPT_GATE_32))
        idt.set_entry (&h21, @int_stub_33, &h08, (FLAG_PRESENT or FLAG_PRIVILEGE_RING_0 or FLAG_INTERRUPT_GATE_32))
        idt.set_entry (&h22, @int_stub_34, &h08, (FLAG_PRESENT or FLAG_PRIVILEGE_RING_0 or FLAG_INTERRUPT_GATE_32))
        idt.set_entry (&h23, @int_stub_35, &h08, (FLAG_PRESENT or FLAG_PRIVILEGE_RING_0 or FLAG_INTERRUPT_GATE_32))
        idt.set_entry (&h24, @int_stub_36, &h08, (FLAG_PRESENT or FLAG_PRIVILEGE_RING_0 or FLAG_INTERRUPT_GATE_32))
        idt.set_entry (&h25, @int_stub_37, &h08, (FLAG_PRESENT or FLAG_PRIVILEGE_RING_0 or FLAG_INTERRUPT_GATE_32))
        idt.set_entry (&h26, @int_stub_38, &h08, (FLAG_PRESENT or FLAG_PRIVILEGE_RING_0 or FLAG_INTERRUPT_GATE_32))
        idt.set_entry (&h27, @int_stub_39, &h08, (FLAG_PRESENT or FLAG_PRIVILEGE_RING_0 or FLAG_INTERRUPT_GATE_32))
        idt.set_entry (&h28, @int_stub_40, &h08, (FLAG_PRESENT or FLAG_PRIVILEGE_RING_0 or FLAG_INTERRUPT_GATE_32))
        idt.set_entry (&h29, @int_stub_41, &h08, (FLAG_PRESENT or FLAG_PRIVILEGE_RING_0 or FLAG_INTERRUPT_GATE_32))
        idt.set_entry (&h2A, @int_stub_42, &h08, (FLAG_PRESENT or FLAG_PRIVILEGE_RING_0 or FLAG_INTERRUPT_GATE_32))
        idt.set_entry (&h2B, @int_stub_43, &h08, (FLAG_PRESENT or FLAG_PRIVILEGE_RING_0 or FLAG_INTERRUPT_GATE_32))
        idt.set_entry (&h2C, @int_stub_44, &h08, (FLAG_PRESENT or FLAG_PRIVILEGE_RING_0 or FLAG_INTERRUPT_GATE_32))
        idt.set_entry (&h2D, @int_stub_45, &h08, (FLAG_PRESENT or FLAG_PRIVILEGE_RING_0 or FLAG_INTERRUPT_GATE_32))
        idt.set_entry (&h2E, @int_stub_46, &h08, (FLAG_PRESENT or FLAG_PRIVILEGE_RING_0 or FLAG_INTERRUPT_GATE_32))
        idt.set_entry (&h2F, @int_stub_47, &h08, (FLAG_PRESENT or FLAG_PRIVILEGE_RING_0 or FLAG_INTERRUPT_GATE_32))
        
        '' and our syscall-interrupt
        idt.set_entry (&h62, @int_stub_98, &h08, (FLAG_PRESENT or FLAG_PRIVILEGE_RING_3 or FLAG_INTERRUPT_GATE_32))
        
        idt.descriptor.limit = idt.TABLE_SIZE*8-1     '' calculate the size of the entries + null-entry
        idt.descriptor.base  = cuint(@idt.table(0))   '' set the address of the table
        asm lidt [idt.descriptor]                     '' load the IDT
    end sub
    
    
    '' this sub is just a helper function to put the passed arguments in the right place of an IDT-entry
    sub set_entry (index as ushort, offset as any ptr, selector as ushort, accessbyte as ubyte)
        idt.table(index).offset_low  = loword(cuint(offset))
        idt.table(index).offset_high = hiword(cuint(offset))
        idt.table(index).selector    = selector
        idt.table(index).reserved    = 0
        idt.table(index).accessbyte  = accessbyte
    end sub
end namespace
