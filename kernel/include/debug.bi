#include "video.bi"

namespace debug
    const INFO as ubyte = 1
    
    common shared loglevel as ubyte = 0
    
    declare sub set_loglevel (level as ubyte)
    
    #macro debug.wlog (level, fstr, args...)
        if (level>loglevel) then video.fout(fstr, args...)
    #endmacro
end namespace
