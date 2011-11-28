namespace video
    declare sub scroll_screen ()
    declare sub cout overload (outstr as zstring)
    declare sub fout (fstr as zstring, ...)
    declare sub cout overload (number as uinteger, base as ubyte = 10, minchars as ubyte = 0)
    declare sub cout overload (number as integer, base as ubyte = 10, minchars as ubyte = 0)
    declare sub clean overload ()
    declare sub clean overload (b_color as ubyte)
    declare sub set_color (fc as ubyte, bc as ubyte)
    declare sub remove_cursor ()
end namespace
