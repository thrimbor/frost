#pragma once

namespace smp
	const FP_SIGNATURE as uinteger = asc("_") or (asc("M") shl 8) or (asc("P") shl 16) or (asc("_") shl 24)

	type floating_pointer_type field=1
		signature as uinteger
		config_table as uinteger
		length as ubyte
		version as ubyte
		checksum as ubyte
		features(0 to 4) as ubyte
	end type

	'declare function find_floating_pointer () as floating_pointer_type ptr
	declare sub init ()
end namespace
