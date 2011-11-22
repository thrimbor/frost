#include once "debug.bi"
#include once "video.bi"

namespace debug
    
    '' this code just is a wrapper for the video-code which allows a loglevel to be set.
    '' if the passed loglevel is higher than the current one the text is allowed to be printed.
    
    dim shared loglevel as ubyte
    
    sub set_loglevel (level as ubyte)
        loglevel = level
    end sub
    
    sub wlog (level as ubyte, outstr as zstring)
        if (level>loglevel) then video.cout(outstr)
    end sub
    
    sub wlog (level as ubyte, number as uinteger, base as ubyte = 10, minchars as ubyte = 0)
        if (level>loglevel) then video.cout(number, base, minchars)
    end sub
    
    sub wlog (level as ubyte, number as integer, base as ubyte = 10, minchars as ubyte = 0)
        if (level>loglevel) then video.cout(number, base, minchars)
    end sub
    
end namespace
