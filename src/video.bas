namespace video
    
    dim shared mempointer as byte ptr = cast(byte ptr, &hB8000)  '// pointer to video-memory
    dim shared cursor_pos as uinteger = 0                        '// the position of the cursor
    dim shared textColor as ubyte = 7                            '// the color of the text
    
    '// todo:
    '//   - use memcopy instead. copying single bytes is inefficient.
    sub scroll_screen ()
        dim rowcounter as uinteger                                 '// a counter for the current row
        dim colcounter as uinteger                                 '// a counter for the current column
        
        for rowcounter = 0 to 24                                   '// for all rows-1
            for colcounter = 0 to 79                               '// for all columns
                *(mempointer+rowcounter*160+colcounter*2)   = *(mempointer+(rowcounter+1)*160+colcounter*2)   '// copy the char from the next row to this row
                *(mempointer+rowcounter*160+colcounter*2+1) = *(mempointer+(rowcounter+1)*160+colcounter*2+1) '// copy the color-byte also
            next colcounter
        next rowcounter
        
        cursor_pos -= 160    
    end sub
    
    sub put_char (char as byte)
        if char = 10 then                                          '// new line character ?
            mempointer += 160                                      '// go one row down
            exit sub                                               '// exit the sub
        end if
        
        if cursor_pos > 3999 then scroll_screen                    '// if we would write outside the screen we scroll it '// (80*25*2)-1
        *(mempointer+cursor_pos) = char                            '// copy the char into the video-memory
        *(mempointer+cursor_pos+1) = textColor                     '// set the color of the char
        cursor_pos += 2                                            '// add 2 bytes to the position (one for the char and one for the color)
    end sub
    
    sub cout (outstr as zstring)
        dim zstr as byte ptr = cast(byte ptr, @outstr)
        do until *zstr = 0
            put_char(*zstr)
            zstr += 1
        loop
    end sub
    
    sub clear_screen ()
        dim clspos as uinteger                                     '// a variable to hold the position
        cursor_pos = 0                                             '// set the screenposition to zero
        
        for clspos = 0 to 80*25                                    '// a loop for all rows & columns
            *(mempointer + clspos*2) = 32                        '// set the char to a space
            *(mempointer + clspos*2+1) = 0                       '// set the color to zero (black)
        next
        end sub
end namespace
