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
#include "video.bi"
#include "mem.bi"
#include "debug.bi"
#include "in_out.bi"

dim shared memory as ubyte ptr = cast(ubyte ptr, &hB8000)  '' pointer to video-memory
dim shared cursor_pos as addr_t = 0                        '' the position of the cursor
dim shared cursor_hidden as boolean = false
dim shared textColor as ubyte = 7                          '' the color of the text
dim shared loglevel as ubyte = LOGLEVEL_DEBUG
dim shared serial_colorized as integer = false

declare sub video_update_cursor ()
declare sub put_uint (number as uinteger, numerical_base as const ubyte = 10, minchars as const ubyte = 1, fillchar as ubyte = 32, lowercase as const boolean = false)
declare sub put_int (number as integer, numerical_base as const ubyte = 10, minchars as const ubyte = 1, fillchar as const ubyte = 32)
declare sub video_set_color (foreground_color as ubyte, background_color as ubyte)

sub video_serial_set_colorized (b as integer)
	serial_colorized = b
end sub

'' scroll the screen down one row
sub video_scroll_screen ()
	memcpy(memory, memory+160, 3840)
	memset(memory+3840, 0, 160)

	cursor_pos -= 160
end sub

'' FIXME: clean up and comment
function parse_color (colorstring as const ubyte ptr) as integer
	if (colorstring[0] <> asc("[")) then return 0

	if (colorstring[1] = 0) then return 0

	if (colorstring[2] = 0) then return 0


	if (colorstring[1] = asc("0") and colorstring[2] = asc("m")) then
		'' reset colors
        if (serial_colorized) then
    		debug_serial_putc(&h1b)
    		debug_serial_putc(asc("["))
    		debug_serial_putc(asc("0"))
    		debug_serial_putc(asc("m"))
        end if
		video_set_color(7, 0)
		return 3
	end if

	if (colorstring[3] <> asc("m")) then return 0
	if (colorstring[1] <> asc("3")) then return 0

	if (colorstring[2] < asc("8")) then
		dim fcolor as ubyte = 0
		'' translate ANSI sequences into VGA colors
		select case colorstring[2]
			case asc("0") : fcolor = 0
			case asc("1") : fcolor = 4
			case asc("2") : fcolor = 2
			case asc("3") : fcolor = 14
			case asc("4") : fcolor = 9
			case asc("5") : fcolor = 5
			case asc("6") : fcolor = 3
			case asc("7") : fcolor = 7
		end select
		video_set_color(fcolor, 0)
		if (serial_colorized) then
            debug_serial_putc(&h1b)
			debug_serial_putc(asc("["))
			debug_serial_putc(asc("3"))
			debug_serial_putc(colorstring[2])
			debug_serial_putc(asc("m"))
		end if
		return 4
	end if
	return 0
end function

'' print one char
sub putc (char as ubyte)
	#if defined (FROST_DEBUG)
		debug_serial_putc(char)
	#endif

	select case (char)
		'' backspace
		case &h08
			if (cursor_pos > 0) then cursor_pos -= 1
		'' tab
		case &h09
			cursor_pos = (cursor_pos + 8) and &hFFFFFFF8
		'' line feed
		case &h0A
			cursor_pos += 160 - (cursor_pos mod 160)
		'' carriage return
		case &h0D
			cursor_pos -= cursor_pos mod 160
		'' printable character
		case is >= &h20
			memory[cursor_pos]   = char
			memory[cursor_pos+1] = textColor
			cursor_pos += 2
	end select

	if (cursor_pos > 3999) then
		video_scroll_screen()
	end if
end sub

sub printk (format_string as const zstring, ...)
    dim fstr as const ubyte ptr = cast(const ubyte ptr, @format_string)
    dim arg as any ptr = va_first()
    dim c as uinteger = 0
    dim is_format as boolean = false
    var format_minchars = 1
    var format_fillchar = asc(" ")

    if (fstr[0] = 2) then
		if fstr[1] = 0 or fstr[1]-asc("0")>loglevel then exit sub
		c+=2
	end if

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
                case &h1b
                    '' parsing ANSI escape sequences is non-trivial, so we have a separate function
                    c += parse_color(fstr+c+1)
                case else
                    putc(fstr[c])
            end select
        end if

        c += 1
    wend

	video_update_cursor()
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

'' clear the screen with a given color
sub video_clean ()
	memset(memory, 0, 4000)
	cursor_pos = 0
end sub

'' set the foreground and background color (only used internally in the video-subsystem)
sub video_set_color (foreground_color as ubyte, background_color as ubyte)
	textColor = ((background_color and &h0F) shl 4) or (foreground_color and &h0F)
end sub

sub video_update_cursor ()
	if (not cursor_hidden) then
		outb(&h3D4, 14)
		outb(&h3D5, cubyte(((cursor_pos shr 1) + 1) shr 8))
		outb(&h3D4, 15)
		outb(&h3D5, cubyte(((cursor_pos shr 1) + 1)))
	end if
end sub

sub video_hide_cursor ()
	cursor_hidden = true
	outb(&h3D4, 14)
	outb(&h3D5, &h07)
	outb(&h3D4, 15)
	outb(&h3D5, &hD0)
end sub

sub video_show_cursor ()
	cursor_hidden = false
	video_update_cursor()
end sub

sub video_move_cursor (x as ubyte, y as ubyte)
	dim t_cursor as uinteger = y*160 + x*2
	if (t_cursor > 3999) then return

	cursor_pos = t_cursor
	video_update_cursor()
end sub
