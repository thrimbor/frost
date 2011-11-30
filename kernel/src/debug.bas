#include once "debug.bi"
#include once "video.bi"

namespace debug
    
    '' this code just is a wrapper for the video-code which allows a loglevel to be set.
    '' if the passed loglevel is higher than the current one the text is allowed to be printed.
    sub set_loglevel (level as ubyte)
        loglevel = level
    end sub
end namespace
