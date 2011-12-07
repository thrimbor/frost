#include once "video.bi"
#include once "kmm.bi"

namespace video
    dim shared memory as ubyte ptr = cast(ubyte ptr, &hB8000)      '' pointer to video-memory
    dim shared cursor_pos as addr_t = 0                        '' the position of the cursor
    dim shared textColor as ubyte = 7                            '' the color of the text
    
    
    '' scroll the screen down one row
    sub scroll_screen ()
        memcpy(memory, memory+160, 3840)
        memset(memory+3840, 0, 160)
        
        cursor_pos -= 160    
    end sub
    
    '' print one char
    sub putc (char as ubyte)
        if (char=10) then
            cursor_pos = (cursor_pos\160+1)*160
            return
        end if
        
        while (cursor_pos>3999)
            scroll_screen()
        wend
        
        memory[cursor_pos]   = char
        memory[cursor_pos+1] = textColor
        
        cursor_pos += 2
    end sub
    
    sub fout (fstr as zstring, ...)
		dim zstr as ubyte ptr = cast(ubyte ptr, @fstr)
		dim counter as uinteger = 0
        dim hcounter as uinteger = 0
        dim nbase as uinteger = 0
		dim arg as any ptr = va_first()
		
        while zstr[counter]
			'' check whether it's a backslash
            if (zstr[counter] = 92) then
                counter += 1
                select case (zstr[counter])
                    '' another backslash? just print one and we're done
                    case 92:
                        putc(zstr[counter])
                        counter += 1
                        continue while
                    '' \n - call putc with the newline-char
                    case 110:
                        putc(10)
                        counter += 1
                        continue while
                    '' a percent sign? just print it
                    case 37:
                        putc(zstr[counter])
                        counter += 1
                        continue while
                    case else:
                        counter += 1
                        continue while
                end select
            end if
            
            '' check whether it's a percent-sign
            if (zstr[counter] = 37) then
				counter += 1
                
                nbase = 10
                select case (zstr[counter])
                    '' "h"
                    case 104:
                        nbase = 16
                        counter += 1
                    '' "n"
                    case 110:
                        nbase = 2
                        counter += 1
                end select
                
                hcounter = 0
                while (zstr[counter] = 35)
                    hcounter += 1
                    counter += 1
                wend
                
				select case (zstr[counter])
					'' "I"
                    case 73:
						if (hcounter > 0) then
                            video.cout(va_arg(arg, uinteger),nbase,hcounter)
                        else
                            video.cout(va_arg(arg, uinteger),nbase)
                        end if
                        
						arg = va_next(arg, uinteger)
						counter += 1
						continue while
                    '' "i"
                    case 105:
                        if (hcounter > 0) then
                            video.cout(va_arg(arg, integer),nbase,hcounter)
                        else
                            video.cout(va_arg(arg, integer),nbase)
                        end if
                        arg = va_next(arg, integer)
                        counter += 1
                        continue while
                    '' "S"
                    case 83:
                        if (hcounter > 0) then
                            video.cout(cuint(va_arg(arg, ushort)),nbase,hcounter)
                        else
                            video.cout(cuint(va_arg(arg, ushort)),nbase)
                        end if
                        arg = va_next(arg, ushort)
                        counter += 1
                        continue while
                    '' "s"
                    case 115:
                        if (hcounter > 0) then
                            video.cout(cint(va_arg(arg, short)),nbase,hcounter)
                        else
                            video.cout(cint(va_arg(arg, short)),nbase)
                        end if
                        arg = va_next(arg, short)
                        counter += 1
                        continue while
                    '' "B"
                    case 66:
                        if (hcounter > 0) then
                            video.cout(cuint(va_arg(arg, ubyte)),nbase,hcounter)
                        else
                            video.cout(cuint(va_arg(arg, ubyte)),nbase)
                        end if
                        arg = va_next(arg, ubyte)
                        counter += 1
                        continue while
                    '' "b"
                    case 98:
                        if (hcounter > 0) then
                            video.cout(cint(va_arg(arg, byte)),nbase,hcounter)
                        else
                            video.cout(cint(va_arg(arg, byte)),nbase)
                        end if
                        arg = va_next(arg, byte)
                        counter += 1
                        continue while
                    '' "z"
                    case 122:
                        dim t_zstr as byte ptr
                        dim t_zcounter as addr_t = 0
                        
                        t_zstr = cast(byte ptr, va_arg(arg, addr_t))
                        arg = va_next(arg, addr_t)
                        
                        while not (t_zstr[t_zcounter] = 0)
                            putc(t_zstr[t_zcounter])
                            t_zcounter += 1
                        wend
                        
                        counter += 1
                        continue while
                    case else:
                        counter += 1
                        continue while
				end select
			end if
			
			putc(zstr[counter])
			counter += 1
		wend
	end sub
		
		
    
    '' print an uinteger with a given base and at least so many chars as given in minchars
    sub cout (number as uinteger, base as ubyte = 10, minchars as ubyte = 0)
        if ((base > 36) or (base < 2)) then return
        dim chars(1 to 10) as ubyte
        dim num as ubyte
        dim counter as uinteger = 10
        dim rem_chars as integer = minchars
        
        do
            chars(counter) = 48+(number mod base)
            if (chars(counter)>57) then chars(counter) += 7
            counter -= 1
            number \= base
            rem_chars -= 1
        loop until ((number <= 0) and (rem_chars <= 0))
        
        for counter = 1 to 10
            if ((chars(counter)=0) and (num = 0)) then continue for
            putc(chars(counter))
            num = 1
        next
    end sub
    
    '' same game with integers. if the number is negative we just print a minus and then the number.
    sub cout (number as integer, base as ubyte = 10, minchars as ubyte = 0)
        if ((base > 36) or (base < 2)) then return
        if (number<0) then
            putc(45)
            number = -number
        end if
        video.cout(cuint(number),base,minchars)
    end sub
    
    '' clear the whole screen
    sub clean ()
        memset(memory, 0, 4000)                         '' set the complete screen to zero (and black)
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
    
    '' removes the cursor from the screen
    sub remove_cursor ()
        out(&h3D4,14)
        out(&h3D5,&h07)
        out(&h3D4,15)
        out(&h3D5,&hD0)
    end sub
    
end namespace
