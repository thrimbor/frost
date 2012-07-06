#include once "zstring.bi"

'' this function searches for the string-terminator (\0)
'' to find out the lenght of the string
function z_len (text as zstring) as uinteger
    dim text_ptr as ubyte ptr = @text
    dim counter as uinteger = 0
    while (text_ptr[counter] > 0)
        counter += 1
    wend
    return counter
end function

'' this is a simple function to find out if and where a string is containing another
function z_instr (text as zstring, pattern as zstring) as uinteger
    dim is_instr    as ubyte
    dim len_text    as uinteger = z_len(text)
    dim len_pattern as uinteger = z_len(pattern)
    dim text_ptr    as ubyte ptr = @text
    dim pattern_ptr as ubyte ptr = @pattern
    
    if (len_text < len_pattern) then return 0
    
    for i as uinteger = 0 to len_text-len_pattern
        is_instr = 1
        for x as uinteger = 0 to len_pattern-1
            if (text_ptr[i+x] <> pattern_ptr[x]) then is_instr = 0
        next
        if (is_instr=1) then return i+1
    next
end function