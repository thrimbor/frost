#include "video.bi"

namespace debug
    const INFO as ubyte = 1
    
    common shared loglevel as ubyte
    
    declare sub set_loglevel (level as ubyte)

    #macro debug_wlog(level, fstr, args...)
		if (level>debug.loglevel) then video.fout(fstr, args)
	#endmacro
end namespace
