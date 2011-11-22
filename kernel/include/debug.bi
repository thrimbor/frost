namespace debug
    const INFO as ubyte = 1
    
    declare sub set_loglevel (level as ubyte)
    declare sub wlog overload (level as ubyte, outstr as zstring)
    declare sub wlog overload (level as ubyte, number as uinteger, base as ubyte = 10, minchars as ubyte = 0)
    declare sub wlog overload (level as ubyte, number as integer, base as ubyte = 10, minchars as ubyte = 0)
end namespace
