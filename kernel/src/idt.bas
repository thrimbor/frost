#include once "idt.bi"
#include once "interrupt_handler.bi"

namespace idt
    dim shared idtp as idt.table_descriptor
    dim shared table (0 to idt.table_size-1) as idt.gate_descriptor
    
    '' this sub sets up and loads an IDT for exceptions, IRQs and the syscall-interrupt.
    sub init ()
        '' register the handlers for the exceptions
        idt.set_entry (&h00, cuint(@int_stub_0), &h08, (FLAG_PRESENT or FLAG_PRIVILEGE_RING_0 or FLAG_INTERRUPT_GATE_32))
        idt.set_entry (&h01, cuint(@int_stub_1), &h08, (FLAG_PRESENT or FLAG_PRIVILEGE_RING_0 or FLAG_INTERRUPT_GATE_32))
        idt.set_entry (&h02, cuint(@int_stub_2), &h08, (FLAG_PRESENT or FLAG_PRIVILEGE_RING_0 or FLAG_INTERRUPT_GATE_32))
        idt.set_entry (&h03, cuint(@int_stub_3), &h08, (FLAG_PRESENT or FLAG_PRIVILEGE_RING_0 or FLAG_INTERRUPT_GATE_32))
        idt.set_entry (&h04, cuint(@int_stub_4), &h08, (FLAG_PRESENT or FLAG_PRIVILEGE_RING_0 or FLAG_INTERRUPT_GATE_32))
        idt.set_entry (&h05, cuint(@int_stub_5), &h08, (FLAG_PRESENT or FLAG_PRIVILEGE_RING_0 or FLAG_INTERRUPT_GATE_32))
        idt.set_entry (&h06, cuint(@int_stub_6), &h08, (FLAG_PRESENT or FLAG_PRIVILEGE_RING_0 or FLAG_INTERRUPT_GATE_32))
        idt.set_entry (&h07, cuint(@int_stub_7), &h08, (FLAG_PRESENT or FLAG_PRIVILEGE_RING_0 or FLAG_INTERRUPT_GATE_32))
        idt.set_entry (&h08, cuint(@int_stub_8), &h08, (FLAG_PRESENT or FLAG_PRIVILEGE_RING_0 or FLAG_INTERRUPT_GATE_32))
        idt.set_entry (&h09, cuint(@int_stub_9), &h08, (FLAG_PRESENT or FLAG_PRIVILEGE_RING_0 or FLAG_INTERRUPT_GATE_32))
        idt.set_entry (&h0A, cuint(@int_stub_10), &h08, (FLAG_PRESENT or FLAG_PRIVILEGE_RING_0 or FLAG_INTERRUPT_GATE_32))
        idt.set_entry (&h0B, cuint(@int_stub_11), &h08, (FLAG_PRESENT or FLAG_PRIVILEGE_RING_0 or FLAG_INTERRUPT_GATE_32))
        idt.set_entry (&h0C, cuint(@int_stub_12), &h08, (FLAG_PRESENT or FLAG_PRIVILEGE_RING_0 or FLAG_INTERRUPT_GATE_32))
        idt.set_entry (&h0D, cuint(@int_stub_13), &h08, (FLAG_PRESENT or FLAG_PRIVILEGE_RING_0 or FLAG_INTERRUPT_GATE_32))
        idt.set_entry (&h0E, cuint(@int_stub_14), &h08, (FLAG_PRESENT or FLAG_PRIVILEGE_RING_0 or FLAG_INTERRUPT_GATE_32))
        idt.set_entry (&h0F, cuint(@int_stub_15), &h08, (FLAG_PRESENT or FLAG_PRIVILEGE_RING_0 or FLAG_INTERRUPT_GATE_32))
        idt.set_entry (&h10, cuint(@int_stub_16), &h08, (FLAG_PRESENT or FLAG_PRIVILEGE_RING_0 or FLAG_INTERRUPT_GATE_32))
        idt.set_entry (&h11, cuint(@int_stub_17), &h08, (FLAG_PRESENT or FLAG_PRIVILEGE_RING_0 or FLAG_INTERRUPT_GATE_32))
        idt.set_entry (&h12, cuint(@int_stub_18), &h08, (FLAG_PRESENT or FLAG_PRIVILEGE_RING_0 or FLAG_INTERRUPT_GATE_32))
        '' 19-31 are reserved
        
        '' now the IRQ's
        idt.set_entry (&h20, cuint(@int_stub_32), &h08, (FLAG_PRESENT or FLAG_PRIVILEGE_RING_0 or FLAG_INTERRUPT_GATE_32))
        idt.set_entry (&h21, cuint(@int_stub_33), &h08, (FLAG_PRESENT or FLAG_PRIVILEGE_RING_0 or FLAG_INTERRUPT_GATE_32))
        idt.set_entry (&h22, cuint(@int_stub_34), &h08, (FLAG_PRESENT or FLAG_PRIVILEGE_RING_0 or FLAG_INTERRUPT_GATE_32))
        idt.set_entry (&h23, cuint(@int_stub_35), &h08, (FLAG_PRESENT or FLAG_PRIVILEGE_RING_0 or FLAG_INTERRUPT_GATE_32))
        idt.set_entry (&h24, cuint(@int_stub_36), &h08, (FLAG_PRESENT or FLAG_PRIVILEGE_RING_0 or FLAG_INTERRUPT_GATE_32))
        idt.set_entry (&h25, cuint(@int_stub_37), &h08, (FLAG_PRESENT or FLAG_PRIVILEGE_RING_0 or FLAG_INTERRUPT_GATE_32))
        idt.set_entry (&h26, cuint(@int_stub_38), &h08, (FLAG_PRESENT or FLAG_PRIVILEGE_RING_0 or FLAG_INTERRUPT_GATE_32))
        idt.set_entry (&h27, cuint(@int_stub_39), &h08, (FLAG_PRESENT or FLAG_PRIVILEGE_RING_0 or FLAG_INTERRUPT_GATE_32))
        idt.set_entry (&h28, cuint(@int_stub_40), &h08, (FLAG_PRESENT or FLAG_PRIVILEGE_RING_0 or FLAG_INTERRUPT_GATE_32))
        idt.set_entry (&h29, cuint(@int_stub_41), &h08, (FLAG_PRESENT or FLAG_PRIVILEGE_RING_0 or FLAG_INTERRUPT_GATE_32))
        idt.set_entry (&h2A, cuint(@int_stub_42), &h08, (FLAG_PRESENT or FLAG_PRIVILEGE_RING_0 or FLAG_INTERRUPT_GATE_32))
        idt.set_entry (&h2B, cuint(@int_stub_43), &h08, (FLAG_PRESENT or FLAG_PRIVILEGE_RING_0 or FLAG_INTERRUPT_GATE_32))
        idt.set_entry (&h2C, cuint(@int_stub_44), &h08, (FLAG_PRESENT or FLAG_PRIVILEGE_RING_0 or FLAG_INTERRUPT_GATE_32))
        idt.set_entry (&h2D, cuint(@int_stub_45), &h08, (FLAG_PRESENT or FLAG_PRIVILEGE_RING_0 or FLAG_INTERRUPT_GATE_32))
        idt.set_entry (&h2E, cuint(@int_stub_46), &h08, (FLAG_PRESENT or FLAG_PRIVILEGE_RING_0 or FLAG_INTERRUPT_GATE_32))
        idt.set_entry (&h2F, cuint(@int_stub_47), &h08, (FLAG_PRESENT or FLAG_PRIVILEGE_RING_0 or FLAG_INTERRUPT_GATE_32))
        
        '' and our syscall-interrupt
        idt.set_entry (&h62, cuint(@int_stub_98), &h08, (FLAG_PRESENT or FLAG_PRIVILEGE_RING_3 or FLAG_INTERRUPT_GATE_32))
        
        '' now we load the idt
        idt.idtp.limit = idt.table_size*8-1
        idt.idtp.base  = cuint(@idt.table(0))
        asm lidt [idt.idtp]
    end sub
    
    
    '' this sub is just a helper function to put the passed arguments in the right place of an IDT-entry
    sub set_entry (i as ushort, offset as uinteger, selector as ushort, accessbyte as ubyte)
        idt.table(i).offset_low  = loword(offset)
        idt.table(i).offset_high = hiword(offset)
        idt.table(i).selector    = selector
        idt.table(i).reserved    = 0
        idt.table(i).accessbyte  = accessbyte
    end sub
end namespace
