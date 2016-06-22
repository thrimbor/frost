/'
 ' FROST
 ' Copyright (C) 2016  Stefan Schmidt
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

'' Bochs Graphics Adapter

'' TODO: use PCI to find the BGA & the LFB address

#include "../../libfrost/frost.bi"

#define VBE_DISPI_IOPORT_INDEX &h01CE
#define VBE_DISPI_IOPORT_DATA  &h01CF
#define VBE_DISPI_INDEX_ID              &h0
#define VBE_DISPI_INDEX_XRES            &h1
#define VBE_DISPI_INDEX_YRES            &h2
#define VBE_DISPI_INDEX_BPP             &h3
#define VBE_DISPI_INDEX_ENABLE          &h4
#define VBE_DISPI_INDEX_BANK            &h5
#define VBE_DISPI_INDEX_VIRT_WIDTH      &h6
#define VBE_DISPI_INDEX_VIRT_HEIGHT     &h7
#define VBE_DISPI_INDEX_X_OFFSET        &h8
#define VBE_DISPI_INDEX_Y_OFFSET        &h9

#define VBE_DISPI_DISABLED              &h00
#define VBE_DISPI_ENABLED               &h01
#define VBE_DISPI_GETCAPS               &h02
#define VBE_DISPI_8BIT_DAC              &h20
#define VBE_DISPI_LFB_ENABLED           &h40
#define VBE_DISPI_NOCLEARMEM            &h80

declare sub printd (format_string as const zstring, ...)

sub outw (port as ushort, value as ushort)
    asm
        movw dx, [port]
        movw ax, [value]
        outw dx, ax
    end asm
end sub

function inw (port as ushort) as ushort
    asm
        movw dx, [port]
        inw ax, dx
        mov [function], ax
    end asm
end function

sub BgaWrite (index as ushort, value as ushort)
	outw(VBE_DISPI_IOPORT_INDEX, index)
	outw(VBE_DISPI_IOPORT_DATA, value)
end sub

function BgaRead (index as ushort) as ushort
	outw(VBE_DISPI_IOPORT_INDEX, index)
	return inw(VBE_DISPI_IOPORT_DATA)
end function

sub main ()
	'' request access to the BGA's ports
	frost_syscall_port_request(VBE_DISPI_IOPORT_INDEX)
	frost_syscall_port_request(VBE_DISPI_IOPORT_INDEX+1)
	frost_syscall_port_request(VBE_DISPI_IOPORT_DATA)
	frost_syscall_port_request(VBE_DISPI_IOPORT_DATA+1)
	
	dim as ushort maxXres, maxYres, maxBpp
	BgaWrite(VBE_DISPI_INDEX_ENABLE, BgaRead(VBE_DISPI_INDEX_ENABLE) or VBE_DISPI_GETCAPS)
	maxXres = BgaRead(VBE_DISPI_INDEX_XRES)
	maxYres = BgaRead(VBE_DISPI_INDEX_YRES)
	maxBpp = BgaRead(VBE_DISPI_INDEX_BPP)
	BgaWrite(VBE_DISPI_INDEX_ENABLE, BgaRead(VBE_DISPI_INDEX_ENABLE) and (not VBE_DISPI_GETCAPS))
	
	printd(!"max resolution: %ux%ux%u\n", maxXres, maxYres, maxBpp)
	
	frost_syscall_43(strptr(!"initializing BGA...\n"))
	
	dim xres as ushort = 800
	dim yres as ushort = 600
	dim bpp as ushort = 32
	
	BgaWrite(VBE_DISPI_INDEX_ENABLE, VBE_DISPI_DISABLED)
	BgaWrite(VBE_DISPI_INDEX_XRES, xres)
	BgaWrite(VBE_DISPI_INDEX_YRES, yres)
	BgaWrite(VBE_DISPI_INDEX_BPP, bpp)
	BgaWrite(VBE_DISPI_INDEX_ENABLE, VBE_DISPI_ENABLED or VBE_DISPI_LFB_ENABLED)
	
	dim xresCheck as ushort
	dim yresCheck as ushort
	dim bppCheck as ushort
	xresCheck = BgaRead(VBE_DISPI_INDEX_XRES)
	yresCheck = BgaRead(VBE_DISPI_INDEX_YRES)
	bppCheck = BgaRead(VBE_DISPI_INDEX_BPP)
	
	if xres = xresCheck and yres=yresCheck and bpp=bppCheck then
		frost_syscall_43(strptr(!"successfully set the resolution\n"))
	else
		frost_syscall_43(strptr(!"there was an error setting the resolution\n"))
	end if
	
	asm jmp $
end sub


declare sub put_uint (number as uinteger, numerical_base as const ubyte = 10, minchars as const ubyte = 1, fillchar as ubyte = 32, lowercase as const boolean = false)
declare sub put_int (number as integer, numerical_base as const ubyte = 10, minchars as const ubyte = 1, fillchar as const ubyte = 32)

'' print one char
sub putc (char as ubyte)
	dim chars (0 to 1) as ubyte
	chars(1) = 0
	chars(0) = char
	
	frost_syscall_43(@chars(0))
end sub

sub printd (format_string as const zstring, ...)
    dim fstr as const ubyte ptr = cast(const ubyte ptr, @format_string)
    dim arg as any ptr = va_first()
    dim c as uinteger = 0
    dim is_format as boolean = false
    var format_minchars = 1
    var format_fillchar = asc(" ")

    while (fstr[c] <> 0)
        if (is_format) then
            select case fstr[c]
                case asc("%")
                    putc(fstr[c])
                    is_format = false
                case asc("d"), asc("i")
                    put_int(va_arg(arg, integer), 10, format_minchars, format_fillchar)
                    arg = va_next(arg, integer)
                    is_format = false
                case asc("u")
                    put_uint(va_arg(arg, uinteger), 10, format_minchars, format_fillchar)
                    arg = va_next(arg, uinteger)
                    is_format = false
                case asc("x")
                    put_uint(va_arg(arg, uinteger), 16, format_minchars, format_fillchar, true)
                    arg = va_next(arg, uinteger)
                    is_format = false
                case asc("X")
                    put_uint(va_arg(arg, uinteger), 16, format_minchars, format_fillchar)
                    arg = va_next(arg, uinteger)
                    is_format = false
                case asc("c")
					putc(va_arg(arg, byte))
					arg = va_next(arg, byte)
					is_format = false
                case asc("s")
                    dim s_it as uinteger = 0
                    dim s_str as byte ptr = va_arg(arg, byte ptr)
                    arg = va_next(arg, byte ptr)

                    while (s_str[s_it] <> 0)
                        putc(s_str[s_it])
                        s_it += 1
                    wend
                    
                    is_format = false
				case asc("0") to asc("9")
					if (fstr[c] = asc("0") and (fstr[c-1] = asc("%"))) then
						format_fillchar = asc("0")
					else
						format_minchars = format_minchars*10 + (fstr[c] - asc("0"))
					end if
            end select
        else
            select case fstr[c]
                case asc("%")
                    is_format = true
                    format_minchars = 1
                    format_fillchar = asc(" ")
                case else
                    putc(fstr[c])
            end select
        end if

        c += 1
    wend
end sub

'' print an uinteger with a given base and at least as many digits as given in minchars
sub put_uint (number as uinteger, numerical_base as const ubyte = 10, minchars as const ubyte = 1, fillchar as ubyte = 32, lowercase as const boolean = false)
	if ((numerical_base > 36) or (numerical_base < 2)) then return
	if (minchars = 1) then fillchar = asc("0")
	dim chars(1 to 10) as ubyte
	dim num as ubyte
	dim counter as uinteger = 10
	dim rem_chars as integer = minchars

	do
		chars(counter) = 48+(number mod numerical_base)
		if (chars(counter)>57) then chars(counter) += 7
		counter -= 1
		number \= numerical_base
		rem_chars -= 1
	loop until ((number <= 0) and (rem_chars <= 0))

	for counter = 1 to 10
		if ((chars(counter)=0) and (num = 0)) then continue for
		if ((chars(counter)=asc("0")) and (num=0)) then
			putc(fillchar)
		else
			if (lowercase) and cast(boolean, (chars(counter) > 64)) then chars(counter) += 32
			putc(chars(counter))
			num = 1
		end if
	next
end sub

'' same game with integers. if the number is negative we just print a minus and then the number.
sub put_int (number as integer, numerical_base as const ubyte = 10, minchars as const ubyte = 1, fillchar as const ubyte = 32)
	if ((numerical_base > 36) or (numerical_base < 2)) then return
	if (number<0) then
		putc(45)
		number = -number
	end if
	put_uint(cuint(number),numerical_base,minchars,fillchar)
end sub

