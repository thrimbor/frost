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

#include "pic.bi"
#include "in_out.bi"
#include "kernel.bi"

const MASTER_COMMAND as ubyte = &h20
const MASTER_DATA    as ubyte = &h21
const SLAVE_COMMAND  as ubyte = &hA0
const SLAVE_DATA     as ubyte = &hA1

'' the end-of-interrupt command:
const COMMAND_EOI as ubyte = &h20

sub pic_init ()
	'' send ICW1 to both pics
	outb(MASTER_COMMAND, &h11)
	outb(SLAVE_COMMAND, &h11)
	
	'' ICW2 is where we want to map the interrupts
	'' we map them directly after the exceptions
	outb(MASTER_DATA, &h20)
	outb(SLAVE_DATA, &h28)
	
	'' ICW3: tell the PICs that they're connected through IRQ 2
	outb(MASTER_DATA, &h04)
	outb(SLAVE_DATA, &h02)
	
	'' ICW4: tell the PICs we're in 8086-mode
	outb(MASTER_DATA, &h01)
	outb(SLAVE_DATA, &h01)
	
	'' select ISR
	outb(MASTER_COMMAND, &h0B)
	outb(SLAVE_COMMAND, &h0B)
end sub

sub pic_send_eoi (irq as ubyte)
	outb(MASTER_COMMAND, COMMAND_EOI)                '' send the EOI-command to the first PIC
	if (irq>7) then outb(SLAVE_COMMAND, COMMAND_EOI) '' if the irq was above 7, the second PIC needs to be informed also
end sub

function pic_is_spurious (irq as ubyte) as boolean
	if (irq = 7) then
		'' check ISR of the first pic
		if ((inb(MASTER_COMMAND) and &b10000000) = 0) then return true
	elseif (irq = 15) then
		'' check ISR of the second pic
		if ((inb(SLAVE_COMMAND) and &b10000000) = 0) then return true
	end if
	
	return false
end function

sub pic_mask (irq as ubyte)
	dim port as ushort
	
	if (irq < 8) then
		port = MASTER_DATA
	else
		port = SLAVE_DATA
		irq -= 8
	end if
	
	outb(port, (inb(port) or (1 shl irq)))
end sub

sub pic_mask_all ()
	outb(MASTER_DATA, &hFF)
	outb(SLAVE_DATA, &hFF)
end sub

sub pic_unmask (irq as ubyte)
	dim port as ushort
	
	if (irq < 8) then
		port = MASTER_DATA
	else
		port = SLAVE_DATA
		irq -= 8
	end if
	
	outb(port, (inb(port) and not(1 shl irq)))
end sub
