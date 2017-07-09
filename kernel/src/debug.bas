/'
 ' FROST x86 microkernel
 ' Copyright (C) 2010-2017  Stefan Schmidt
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

#include "debug.bi"
#include "kernel.bi"
#include "video.bi"
#include "in_out.bi"


'' this function allows a loglevel to be set which is used by a wrapper for the video-code
sub debug_set_loglevel (level as ubyte)
	debug_loglevel = level
end sub

#if defined (FROST_DEBUG)
	dim shared debug_com_initialized as boolean = false
	dim shared COM1_PORT as ushort = &h3F8

	const REG_IER as ushort = 1 '' [RW] Interrupt Enable Register
	const REG_IIR as ushort = 2 '' [R ] Interrupt Identification Register
	const REG_FCR as ushort = 2 '' [ W] FIFO Control Register
	const REG_LCR as ushort = 3 '' [RW] Line Control Register
	const REG_MCR as ushort = 4 '' [RW] Modem Control Register
	const REG_LSR as ushort = 5 '' [R ] Line Status Register
	const REG_MSR as ushort = 6 '' [R ] Modem Status Register
	const REG_SCR as ushort = 7 '' [RW] Scratch Register

	sub debug_init_com (baud as uinteger, parity as ubyte, bits as ubyte)
		dim divisor as ushort = 115200\baud

		'' DLAB=1
		outb(COM1_PORT+REG_LCR, &h80)

		'' set baud rate divisor
		outb(COM1_PORT, lobyte(divisor))
		outb(COM1_PORT+REG_IER, hibyte(divisor))

		'' set parity, bits-per-byte and DLAB=0
		outb(COM1_PORT+REG_LCR, ((parity and &h07) shl 3) or ((bits-5) and &h03))

		'' no interrupts
		outb(COM1_PORT+REG_IER, 0)

		'' disable FIFOs
		outb(COM1_PORT+REG_FCR, &h00)

		'' disable AUX & loopback
		outb(COM1_PORT+REG_MCR, &h00)
	end sub

	sub debug_serial_init ()
		debug_init_com(19200, 0, 8)
		debug_com_initialized = true
	end sub

	sub debug_serial_putc (char as ubyte)
        '' typical terminal software requires a carriage return, too
        if (char = 10) then
            debug_serial_putc(13)
        end if

		if (debug_com_initialized) then
			'' wait until we can write
			while((inb(COM1_PORT+REG_LSR) and &h20) = 0) : wend
			'' write byte
			outb(COM1_PORT, char)
		end if
	end sub
#endif

sub debug_stacktrace (maxFrames as uinteger)
	dim ebp as uinteger ptr = @maxFrames -2

	ebp = cast(uinteger ptr, ebp)

	printk(LOG_ERR !"stacktrace\n")
	for frame as uinteger = 0 to maxFrames
		dim eip as uinteger = ebp[1]

		if (eip = 0) or (ebp = nullptr) then
			exit for
		end if

		ebp = cast(uinteger ptr, ebp[0])
		printk(LOG_ERR !" 0x%08X\n", eip)
	next
end sub
