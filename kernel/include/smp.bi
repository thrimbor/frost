#pragma once

namespace smp
	const FP_SIGNATURE as uinteger = asc("_") or (asc("M") shl 8) or (asc("P") shl 16) or (asc("_") shl 24)
	const CT_SIGNATURE as uinteger = asc("P") or (asc("C") shl 8) or (asc("M") shl 16) or (asc("P") shl 24)

	type floating_pointer_type field=1
		signature as uinteger
		config_table as uinteger
		length as ubyte
		version as ubyte
		checksum as ubyte
		features(0 to 4) as ubyte
	end type
	
	type config_table_type field=1
		signature as uinteger
		base_table_length as ushort
		spec_revision as ubyte
		checksum as ubyte
		oem_id as zstring*8
		product_id as zstring*12
		oem_table_ptr as uinteger
		oem_table_size as ushort
		entry_count as ushort
		local_apic_address as uinteger
		
		extended_table_length as ushort
		extended_table_checksum as ubyte
		reserved as ubyte
	end type

	declare sub init ()
end namespace
