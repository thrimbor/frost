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

namespace video
    dim shared memory as ubyte ptr = cast(ubyte ptr, &hB8000)      '' pointer to video-memory
    dim shared cursor_pos as addr_t = 0                        '' the position of the cursor
    dim shared cursor_hidden as boolean = false
    dim shared textColor as ubyte = 7                            '' the color of the text
    
    declare sub update_cursor ()
    
    
    '' scroll the screen down one row
    sub scroll_screen ()
        memcpy(memory, memory+160, 3840)
        memset(memory+3840, 0, 160)
        
        cursor_pos -= 160    
    end sub
    
    '' print one char
    sub putc (char as ubyte)
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
        
        while (cursor_pos > 3999)
            scroll_screen()
        wend
    end sub
    
    sub fout (fstr as zstring, ...)
		dim zstr as ubyte ptr    = cast(ubyte ptr, @fstr)
		dim counter as uinteger  = 0
        dim hcounter as uinteger = 0
        dim nbase as uinteger    = 0
		dim arg as any ptr       = va_first()
		
        while zstr[counter]
            if (zstr[counter] = 37) then              '' do we have a percent-sign?
				counter += 1                          '' go to the next char
                
                nbase = 10                            '' preset the base to 10
                select case (zstr[counter])           '' check the char
                    case 104:                         '' a "h"?
                        nbase = 16                    '' set to hexadecimal
                        counter += 1
                    case 110:                         '' a "n"?
                        nbase = 2                     '' set to binary
                        counter += 1
                end select
                
                hcounter = 0                          ''\
                while (zstr[counter] = 35)            '' \
                    hcounter += 1                     ''  > count all the "#"-chars
                    counter += 1                      '' /  this will be the number of minimum chars to print
                wend                                  ''/
                
				select case (zstr[counter])
					'' "I"
                    case 73:
                        video.cout(va_arg(arg, uinteger),nbase,hcounter)
                        
						arg = va_next(arg, uinteger)
						counter += 1
						continue while
                    '' "i"
                    case 105:
                        video.cout(va_arg(arg, integer),nbase,hcounter)
                        
                        arg = va_next(arg, integer)
                        counter += 1
                        continue while
                    '' "S"
                    case 83:
                        video.cout(cuint(va_arg(arg, ushort)),nbase,hcounter)
                        
                        arg = va_next(arg, ushort)
                        counter += 1
                        continue while
                    '' "s"
                    case 115:
                        video.cout(cint(va_arg(arg, short)),nbase,hcounter)
                        
                        arg = va_next(arg, short)
                        counter += 1
                        continue while
                    '' "B"
                    case 66:
                        video.cout(cuint(va_arg(arg, ubyte)),nbase,hcounter)
                        
                        arg = va_next(arg, ubyte)
                        counter += 1
                        continue while
                    '' "b"
                    case 98:
                        video.cout(cint(va_arg(arg, byte)),nbase,hcounter)
                        
                        arg = va_next(arg, byte)
                        counter += 1
                        continue while
                    '' "z"
                    case 122:
                        dim t_zstr as byte ptr
                        dim t_zcounter as addr_t = 0
                        
                        t_zstr = cast(byte ptr, va_arg(arg, addr_t))
                        arg = va_next(arg, addr_t)
                        
                        while (t_zstr[t_zcounter] <> 0)
                            putc(t_zstr[t_zcounter])
                            t_zcounter += 1
                        wend
                        
                        counter += 1
                        continue while
                    '' "%"
                    case &h25:
					    putc(&h25)
					    counter += 1
                    case else:
                        counter += 1
                        continue while
				end select
			end if
			
			putc(zstr[counter])
			counter += 1
		wend
		
		update_cursor()
	end sub
    
    '' print an uinteger with a given base and at least as many chars as given in minchars
    sub cout (number as uinteger, nbase as ubyte = 10, minchars as ubyte = 0)
        if ((nbase > 36) or (nbase < 2)) then return
        dim chars(1 to 10) as ubyte
        dim num as ubyte
        dim counter as uinteger = 10
        dim rem_chars as integer = minchars
        
        do
            chars(counter) = 48+(number mod nbase)
            if (chars(counter)>57) then chars(counter) += 7
            counter -= 1
            number \= nbase
            rem_chars -= 1
        loop until ((number <= 0) and (rem_chars <= 0))
        
        for counter = 1 to 10
            if ((chars(counter)=0) and (num = 0)) then continue for
            putc(chars(counter))
            num = 1
        next
    end sub
    
    '' same game with integers. if the number is negative we just print a minus and then the number.
    sub cout (number as integer, nbase as ubyte = 10, minchars as ubyte = 0)
        if ((nbase > 36) or (nbase < 2)) then return
        if (number<0) then
            putc(45)
            number = -number
        end if
        video.cout(cuint(number),nbase,minchars)
    end sub
    
    '' clear the whole screen
    sub clean ()
        memset(memory, 0, 4000)                                    '' set the complete screen to zero (and black)
        cursor_pos = 0                                             '' reset cursor position
    end sub
    
    '' clear the screen with a given color
    sub clean (b_color as ubyte)
        dim c_word as ushort = (((b_color and &h0F) shl 4) or (textColor and &h0F)) shl 8
        asm
            mov ecx, 2000
            mov edi, [memory]
            mov ax, [c_word]
            
            rep stosw
        end asm
        cursor_pos = 0
    end sub
    
    '' set the foreground and background color
    sub set_color (f_color as ubyte, b_color as ubyte)
        textColor = ((b_color and &h0F) shl 4) or (f_color and &h0F)
    end sub
    
    sub update_cursor ()
		if (not cursor_hidden) then
			out(&h3D4, 14)
			out(&h3D5, cubyte(((cursor_pos shr 1) + 1) shr 8))
			out(&h3D4, 15)
			out(&h3D5, cubyte(((cursor_pos shr 1) + 1)))
		end if
	end sub
    
    '' removes the cursor from the screen
    sub hide_cursor ()
        cursor_hidden = true
        out(&h3D4, 14)
        out(&h3D5, &h07)
        out(&h3D4, 15)
        out(&h3D5, &hD0)
    end sub
    
    sub show_cursor ()
		cursor_hidden = false
		update_cursor()
	end sub
    
    sub move_cursor (x as ubyte, y as ubyte)
        dim t_cursor as uinteger = y*160 + x*2
        if (t_cursor > 3999) then return
        
        cursor_pos = t_cursor
        update_cursor()
    end sub
    
end namespace
