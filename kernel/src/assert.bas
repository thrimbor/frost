#include "video.bi"

#if defined (FROST_DEBUG)

sub _fb_Assert alias "fb_Assert" (byval fname as zstring ptr, byval linenum as integer, byval funcname as zstring ptr, byval expression as zstring ptr)
	video.fout(!"assertion failed: file: %z, function: %z, line: %i, expression: %z\n", fname, funcname, linenum, expression)
	asm cli
	asm hlt
end sub

sub _fb_AssertWarn alias "fb_AssertWarn" (byval fname as zstring ptr, byval linenum as integer, byval funcname as zstring ptr, byval expression as zstring ptr)
	video.fout(!"assertion failed: file: %z, function: %z, line: %i, expression: %z\n", fname, funcname, linenum, expression)
end sub

#endif
