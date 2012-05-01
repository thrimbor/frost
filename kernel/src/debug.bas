#include once "debug.bi"
#include once "video.bi"

namespace debug
    
    '' this function allows a loglevel to be set which is used by a wrapper for the video-code
    sub set_loglevel (level as ubyte)
        loglevel = level
    end sub
end namespace
