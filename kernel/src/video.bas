#include once "inc/video.bi"

namespace video
    dim shared memory as byte ptr = cast(byte ptr, &hB8000)      '// pointer to video-memory
    dim shared cursor_pos as uinteger = 0                        '// the position of the cursor
    dim shared textColor as ubyte = 7                            '// the color of the text
    dim shared be_silent as ubyte = 0
    
    '// todo:
    '//   - use memcopy instead. copying single bytes is inefficient.
    sub scroll_screen ()
        dim rowcounter as uinteger                                 '// a counter for the current row
        dim colcounter as uinteger                                 '// a counter for the current column
        
        for rowcounter = 0 to 24                                   '// for all rows-1
            for colcounter = 0 to 79                               '// for all columns
                *(memory+rowcounter*160+colcounter*2)   = *(memory+(rowcounter+1)*160+colcounter*2)   '// copy the char from the next row to this row
                *(memory+rowcounter*160+colcounter*2+1) = *(memory+(rowcounter+1)*160+colcounter*2+1) '// copy the color-byte also
            next colcounter
        next rowcounter
        
        cursor_pos -= 160    
    end sub
    
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
    
    sub cout (outstr as zstring, flag as ubyte = 0)
        if (be_silent = 1) then return
        dim zstr as byte ptr = cast(byte ptr, @outstr)
        dim counter as uinteger
        
        while not (zstr[counter] = 0)
            putc(zstr[counter])
            counter += 1
        wend
        
        if (flag and video.endl) then putc(10)
    end sub
    
    sub cout (number as uinteger, flag as ubyte = 0)
        if (be_silent = 1) then return
        dim chars(1 to 10) as ubyte
        dim num as ubyte
        dim counter as uinteger = 10
        
        do
            chars(counter) = (number mod 10) + 48
            counter -= 1
            number \= 10
        loop until (number <= 0)
        
        for counter = 1 to 10
            if ((chars(counter)=0) and (num = 0)) then continue for
            putc(chars(counter))
            num = 1
        next
        
        if (flag and video.endl) then putc(10)
    end sub
    
    sub cout (number as integer, flag as ubyte = 0)
        if (be_silent = 1) then return
        dim chars(1 to 10) as ubyte
        dim num as ubyte
        dim counter as uinteger = 10
        dim negative as ubyte = 0
        
        if (number < 0) then
            negative = 1
        end if
        
        do
            if (negative=1) then
                chars(counter) = 48-(number mod 10)
            else
                chars(counter) = 48+(number mod 10)
            end if
            counter -= 1
            number \= 10
        loop until (number=0)
        
        if (negative=1) then putc(45)
        
        for counter = 1 to 10
            if ((chars(counter)=0) and (num=0)) then continue for
            putc(chars(counter))
            num = 1
        next
        
        if (flag and video.endl) then putc(10)
    end sub
    
    sub cout (number as ushort, flag as ubyte = 0)
        if (be_silent = 1) then return
        dim chars(1 to 5) as ubyte
        dim num as ubyte
        dim counter as uinteger = 5
        
        do
            chars(counter) = (number mod 10) + 48
            counter -= 1
            number \= 10
        loop until (number <= 0)
        
        for counter = 1 to 5
            if ((chars(counter)=0) and (num = 0)) then continue for
            putc(chars(counter))
            num = 1
        next
        
        if (flag and video.endl) then putc(10)
    end sub
    
    sub cout (number as short, flag as ubyte = 0)
        if (be_silent = 1) then return
        dim chars(1 to 5) as ubyte
        dim num as ubyte
        dim counter as uinteger = 5
        dim negative as ubyte = 0
        
        if (number < 0) then
            negative = 1
        end if
        
        do
            if (negative=1) then
                chars(counter) = 48-(number mod 10)
            else
                chars(counter) = 48+(number mod 10)
            end if
            counter -= 1
            number \= 10
        loop until (number=0)
        
        if (negative=1) then putc(45)
        
        for counter = 1 to 5
            if ((chars(counter)=0) and (num=0)) then continue for
            putc(chars(counter))
            num = 1
        next
        
        if (flag and video.endl) then putc(10)
    end sub
    
    sub cout (number as ubyte, flag as ubyte = 0)
        if (be_silent = 1) then return
        dim chars(1 to 3) as ubyte
        dim num as ubyte
        dim counter as uinteger = 3
        
        do
            chars(counter) = (number mod 10) + 48
            counter -= 1
            number \= 10
        loop until (number <= 0)
        
        for counter = 1 to 3
            if ((chars(counter)=0) and (num = 0)) then continue for
            putc(chars(counter))
            num = 1
        next
        
        if (flag and video.endl) then putc(10)
    end sub
    
    sub cout (number as byte, flag as ubyte = 0)
        if (be_silent = 1) then return
        dim chars(1 to 3) as ubyte
        dim num as ubyte
        dim counter as uinteger = 3
        dim negative as ubyte = 0
        
        if (number < 0) then
            negative = 1
        end if
        
        do
            if (negative=1) then
                chars(counter) = 48-(number mod 10)
            else
                chars(counter) = 48+(number mod 10)
            end if
            counter -= 1
            number \= 10
        loop until (number=0)
        
        if (negative=1) then putc(45)
        
        for counter = 1 to 3
            if ((chars(counter)=0) and (num=0)) then continue for
            putc(chars(counter))
            num = 1
        next
        
        if (flag and video.endl) then putc(10)
    end sub
    
    sub clean ()
        if (be_silent = 1) then return
        dim clspos as uinteger                                     '// a variable to hold the position
        cursor_pos = 0                                             '// set the screenposition to zero
        
        for clspos = 0 to 80*25                                    '// a loop for all rows & columns
            *(memory + clspos*2) = 32                        '// set the char to a space
            *(memory + clspos*2+1) = 0                       '// set the color to zero (black)
        next
    end sub
    
    sub set_color (fc as ubyte, bc as ubyte)
        textColor = (bc shl 4) or fc
    end sub
    
    sub remove_cursor ()
        out(&h3D4,14)
        out(&h3D5,&h07)
        out(&h3D4,15)
        out(&h3D5,&hD0)
    end sub
    
    sub block_output ()
        be_silent = 1
    end sub
    
    sub unblock_output ()
        be_silent = 0
    end sub
end namespace
