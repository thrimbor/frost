namespace video
    const endl as ubyte = &h01
    
    declare sub scroll_screen ()
    declare sub cout (outstr as zstring, flag as ubyte = 0)
    declare sub clean ()
    declare sub set_color (fc as ubyte, bc as ubyte)
end namespace
