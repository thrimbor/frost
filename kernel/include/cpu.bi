#pragma once
#include "kernel.bi"

namespace cpu
	declare function get_vendor () as zstring ptr
	declare function has_apic () as boolean
end namespace
