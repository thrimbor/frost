namespace video
    
    dim shared memory as byte ptr = cast(byte ptr, &hB8000)      '// pointer to video-memory
    dim shared cursor_pos as uinteger = 0                        '// the position of the cursor
    dim shared textColor as ubyte = 7                            '// the color of the text
    
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
    
    sub cout (outstr as zstring)
        dim zstr as byte ptr = cast(byte ptr, @outstr)
        dim counter as uinteger
        
        while not (zstr[counter] = 0)
            if zstr[counter] = 10 then
                cursor_pos += 160
                continue while
            end if
            if cursor_pos > 3999 then scroll_screen
            
            memory[cursor_pos+(counter*2)] = zstr[counter]
            memory[cursor_pos+(counter*2)+1] = textColor
            
            counter += 1
            cursor_pos += 2
        wend
    end sub
    
    sub clean ()
        dim clspos as uinteger                                     '// a variable to hold the position
        cursor_pos = 0                                             '// set the screenposition to zero
        
        for clspos = 0 to 80*25                                    '// a loop for all rows & columns
            *(memory + clspos*2) = 32                        '// set the char to a space
            *(memory + clspos*2+1) = 0                       '// set the color to zero (black)
        next
        end sub
end namespace
