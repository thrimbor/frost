#pragma once

type rsdp_descriptor_1 field=1
	signature as zstring*8
	checksum as ubyte
	oemid as zstring*6
	revision as ubyte
	rsdt_address as uinteger
end type

type rsdp_descriptor_2 field=1
	signature as zstring*8
	checksum as ubyte
	oemid as zstring*6
	revision as ubyte
	rsdt_address as uinteger
	
	length as uinteger
	xsdt_address as ulongint
	extended_checksum as ubyte
	reserved as zstring*3
end type
