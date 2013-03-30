#pragma once

#include "kernel.bi"
#include "isf.bi"
#include "video.bi"

namespace panic
	common shared clear_on_panic as boolean
    declare sub set_clear_on_panic (b as boolean)
    declare sub hlt ()
    declare sub panic_exception (isf as interrupt_stack_frame ptr)
    
    #macro panic_error (msg, params...)
		asm cli
		video.set_color(0,3)
		if (panic.clear_on_panic) then video.clean(3)
		video.fout(!"\nKERNEL PANIC\n")
		video.fout(!"file: %z, function: %z, line: %I\n\n", @__FILE__, @__FUNCTION__, cuint(__LINE__))
		video.fout(!"reason: ")
		video.fout(msg, params)
		
		panic.hlt()
	#endmacro
end namespace
