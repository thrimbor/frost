namespace video
    const endl as ubyte = &h01
    
    declare sub scroll_screen ()
    declare sub cout overload (outstr as zstring, flag as ubyte = 0)
    declare sub cout overload (number as uinteger, flag as ubyte = 0)
    declare sub cout overload (number as integer, flag as ubyte = 0)
    declare sub cout overload (number as ushort, flag as ubyte = 0)
    declare sub cout overload (number as short, flag as ubyte = 0)
    declare sub cout overload (number as ubyte, flag as ubyte = 0)
    declare sub cout overload (number as byte, flag as ubyte = 0)
    declare sub clean ()
    declare sub set_color (fc as ubyte, bc as ubyte)
    declare sub remove_cursor ()
    declare sub block_output ()
    declare sub unblock_output ()
end namespace
