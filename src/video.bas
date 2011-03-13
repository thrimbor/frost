namespace video
    
    dim shared videopointer as byte ptr = cast(byte ptr, &hB8000)  '// pointer to video-memory
    dim shared videoPos as uinteger = 0                            '// the position of the cursor
    dim shared textColor as ubyte = 7                              '// the color of the text
    
    '// todo:
    '//   - use memcopy instead. copying single bytes is inefficient.
    sub scrollScreen
        dim rowcounter as uinteger                                 '// a counter for the current row
        dim colcounter as uinteger                                 '// a counter for the current column
        
        for rowcounter = 0 to 24                                   '// for all rows-1
            for colcounter = 0 to 79                               '// for all columns
                *(videopointer+rowcounter*160+colcounter*2)   = *(videopointer+(rowcounter+1)*160+colcounter*2)   '// copy the char from the next row to this row
                *(videopointer+rowcounter*160+colcounter*2+1) = *(videopointer+(rowcounter+1)*160+colcounter*2+1) '// copy the color-byte also
            next colcounter
        next rowcounter
        
        videoPos -= 160    
    end sub
end namespace
