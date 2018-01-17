/'
 ' FROST
 ' Copyright (C) 2010-2018  Stefan Schmidt
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

'' PS/2 8042 keyboard controller driver

#include "../../libfrost/frost.bi"
#include "keyboard.bi"

const KBC_COMMAND as ubyte = &h64
const KBC_DATA    as ubyte = &h60

declare sub irq_handler (irq_number as uinteger)
declare sub kbc_send_command (cmd as ubyte)

sub outb (port as ushort, value as ubyte)
    asm
        movw dx, [port]
        movb al, [value]
        outb dx, al
    end asm
end sub

function inb (port as ushort) as ubyte
    asm
        movw dx, [port]
        inb al, dx
        mov [function], al
    end asm
end function

sub main ()
	'' request access to the controller's ports
	frost_syscall_port_request(KBC_COMMAND)
	frost_syscall_port_request(KBC_DATA)
	
	frost_syscall_irq_handler_register(1, @irq_handler)
	
	'' clear the buffer
	while ((inb(KBC_COMMAND) and &h01) <> 0)
		inb(KBC_DATA)
	wend
	
	'' turn the LEDs off
	kbc_send_command(&hED)
	kbc_send_command(&h00)
	
	'' activate the keyboard
	kbc_send_command(&hF4)
	
	frost_syscall_43(strptr("Keyboard controller initialized"))
	
	asm jmp $
end sub

sub irq_handler (irq_number as uinteger)
	while ((inb(KBC_COMMAND) and &h01) <> 0)
		if (irq_number = &h01) then
			dim is_break_code as integer = false
			dim keycode as ubyte
			static e0_code as integer = false
			static e1_code as integer = 0
			static e1_prev as ushort = 0
			dim scancode as ubyte = inb(KBC_DATA)
			
			if (bit(scancode, 7) and (e1_code or (scancode <> &hE1)) and (e0_code or (scancode <> &hE0))) then
				is_break_code = true
				scancode = bitreset(scancode, 7)
			end if
			
			if (e0_code) then
				'' catch fake-shift
				if ((scancode = &h2A) or (scancode = &h36)) then
					e0_code = false
				else
					keycode = scancode_to_keycode(1, scancode)
					e0_code = false
				end if
			elseif (e1_code = 2) then
				'' second (and last) byte of an e1-code
				e1_prev or= cushort(scancode) shl 8
				keycode = scancode_to_keycode(2, e1_prev)
				e1_code = 0
			elseif (e1_code = 1) then
				'' first byte of an e1-code
				e1_prev = scancode
				e1_code += 1
			elseif (scancode = &hE0) then
				'' beginning of an e0-code
				e0_code = true
			elseif (scancode = &hE1) then
				'' beginning of an e1-code
				e1_code = 1
			else
				'' normal scancode
				keycode = scancode_to_keycode(0, scancode)
			end if
			
			if (keycode <> 0) then
				if (is_break_code) then
					frost_syscall_43(strptr("Key released"))
				else
					frost_syscall_43(strptr("Key pressed"))
				end if
			end if
		end if
	wend
	
	frost_syscall_irq_handler_exit(irq_number)
end sub

sub kbc_send_command (cmd as ubyte)
	do
		'' wait until the input buffer is empty
		while ((inb(KBC_COMMAND) and &h02) <> 0)
			frost_syscall_thread_yield()
		wend
		
		outb(KBC_DATA, cmd)
		
		while ((inb(KBC_COMMAND) and &h01) = 0)
			frost_syscall_thread_yield()
		wend
	loop while (inb(KBC_DATA) = &hFE)
end sub
