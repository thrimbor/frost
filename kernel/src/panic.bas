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

#include "panic.bi"
#include "isf.bi"
#include "video.bi"

sub panic_set_clear_on_panic (b as boolean)
	panic_clear_on_panic = b
end sub

sub panic_hlt ()
	printk(LOG_ERR COLOR_RED !"\nSYSTEM HALTED")
	cpu_halt()
end sub

sub panic_exception (isf as interrupt_stack_frame ptr)
	cpu_disable_interrupts()
	if (panic_clear_on_panic) then video_clean()
	printk(LOG_ERR COLOR_RED !"\n--------------------------------------------------------------------------------")
	printk(LOG_ERR !"\nKERNEL PANIC\n")

	select case (isf->int_nr)
		case &h00
			printk(LOG_ERR !"EXCEPTION 0x00 - Division by Zero (#DE)\n")
		case &h01
			printk(LOG_ERR !"EXCEPTION 0x01 - Debug (#DB)\n")
		case &h02
			printk(LOG_ERR !"EXCEPTION 0x02 - Non-maskable Interrupt (#NMI)\n")
		case &h03
			printk(LOG_ERR !"EXCEPTION 0x03 - Breakpoint (#BP)\n")
		case &h04
			printk(LOG_ERR !"EXCEPTION 0x04 - Overflow (#OF)\n")
		case &h05
			printk(LOG_ERR !"EXCEPTION 0x05 - Bound Range Exceeded (#BR)\n")
		case &h06
			printk(LOG_ERR !"EXCEPTION 0x06 - Invalid Opcode (#UD)\n")
		case &h07
			printk(LOG_ERR !"EXCEPTION 0x07 - Device Not Available (#NM)\n")
		case &h08
			printk(LOG_ERR !"EXCEPTION 0x08 - Double Fault (#DF)\n")
		case &h09
			printk(LOG_ERR !"EXCEPTION 0x09 - Coprocessor Segment Overrun\n")
		case &h0A
			printk(LOG_ERR !"EXCEPTION 0x0A - Invalid TSS (#TS)\n")
		case &h0B
			printk(LOG_ERR !"EXCEPTION 0x0B - Segment Not Present (#NP)\n")
		case &h0C
			printk(LOG_ERR !"EXCEPTION 0x0C - Stack-Segment Fault (#SS)\n")
		case &h0D
			printk(LOG_ERR !"EXCEPTION 0x0D - General Protection Fault (#GP)\n")
		case &h0E
			printk(LOG_ERR !"EXCEPTION 0x0E - Page Fault (#PF)\n")
			printk(LOG_ERR COLOR_RED !" - page active  : ")
			if (isf->errorcode and &h01) then
				printk(LOG_ERR COLOR_RESET !"yes\n")
			else
				printk(LOG_ERR COLOR_RESET !"no\n")
			end if
			printk(LOG_ERR COLOR_RED !" - access type  : ")
			if (isf->errorcode and &h02) then
				printk(LOG_ERR COLOR_RESET !"write\n")
			else
				printk(LOG_ERR COLOR_RESET !"read\n")
			end if
			printk(LOG_ERR COLOR_RED !" - rights       : ")
			if (isf->errorcode and &h04) then
				printk(LOG_ERR COLOR_RESET !"user\n")
			else
				printk(LOG_ERR COLOR_RESET !"kernel\n")
			end if
			printk(LOG_ERR COLOR_RED !" - reserved     : ")
			if (isf->errorcode and &h08) then
				printk(LOG_ERR COLOR_RESET !"yes\n")
			else
				printk(LOG_ERR COLOR_RESET !"no\n")
			end if
			printk(LOG_ERR COLOR_RED !" - access target: ")
			if (isf->errorcode and &h10) then
				printk(LOG_ERR COLOR_RESET !"code\n")
			else
				printk(LOG_ERR COLOR_RESET !"data\n")
			end if
		case &h0F
			printk(LOG_ERR !"EXCEPTION 0x0F - RESERVED\n")
		case &h10
			printk(LOG_ERR !"EXCEPTION 0x10 - x87 Floating Point (#MF)\n")
		case &h11
			printk(LOG_ERR !"EXCEPTION 0x11 - Alignment Check (#AC)\n")
		case &h12
			printk(LOG_ERR !"EXCEPTION 0x12 - Machine Check (#MC)\n")
		case &h13
			printk(LOG_ERR !"EXCEPTION 0x13 - SIMD Floating Point (#XM/#XF)\n")
		case &h14 to &h1F
			printk(LOG_ERR !"EXCEPTION - RESERVED EXCEPTION\n")
	end select

	printk(LOG_ERR !"\n")
	printk(LOG_ERR COLOR_RED "error: " COLOR_RESET !"0x%08X\n", isf->errorcode)

	dim as uinteger t_cr0, t_cr2, t_cr3

	asm
		mov eax, cr0
		mov [t_cr0], eax
		mov eax, cr2
		mov [t_cr2], eax
		mov eax, cr3
		mov [t_cr3], eax
	end asm
	printk(LOG_ERR COLOR_RED "cr0: " COLOR_RESET "0x%08X" COLOR_RED ", cr2: " COLOR_RESET "0x%08X" COLOR_RED ", cr3: " COLOR_RESET !"0x%08X\n", t_cr0, t_cr2, t_cr3)
	printk(LOG_ERR COLOR_RED "eax: " COLOR_RESET "0x%08X" COLOR_RED ", ebx: " COLOR_RESET "0x%08X" COLOR_RED ", ecx: " COLOR_RESET "0x%08X" COLOR_RED ", edx: " COLOR_RESET !"0x%08X\n", isf->eax, isf->ebx, isf->ecx, isf->edx)
	printk(LOG_ERR COLOR_RED "ebp: " COLOR_RESET "0x%08X" COLOR_RED ", esp: " COLOR_RESET "0x%08X" COLOR_RED ", esi: " COLOR_RESET "0x%08X" COLOR_RED ", edi: " COLOR_RESET !"0x%08X\n", isf->ebp, isf->esp, isf->esi, isf->edi)
	printk(LOG_ERR COLOR_RED "eip: " COLOR_RESET "0x%08X" COLOR_RED ",  ss: " COLOR_RESET "0x%04X" COLOR_RED ",  cs: " COLOR_RESET "0x%04X" COLOR_RED ", eflags: " COLOR_RESET !"0x%08X\n", isf->eip, isf->ss, isf->cs, isf->eflags)

	' maybe print some other registers here
	panic_hlt()
end sub
