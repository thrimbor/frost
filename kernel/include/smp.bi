/'
 ' FROST x86 microkernel
 ' Copyright (C) 2010-2013  Stefan Schmidt
 ' 
 ' This program is free software: you can redistribute it and/or modify
 ' it under the terms of the GNU General Public License as published by
 ' the Free Software Foundation, either version 3 of the License, or
 ' (at your option) any later version.
 ' 
 ' This program is distributed in the hope that it will be useful,
 ' but WITHOUT ANY WARRANTY; without even the implied warranty of
 ' MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 ' GNU General Public License for more details.
 ' 
 ' You should have received a copy of the GNU General Public License
 ' along with this program.  If not, see <http://www.gnu.org/licenses/>.
 '/

#pragma once

namespace smp
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
	
	enum CT_ENTRY_TYPES explicit
		PROCESSOR = 0
		BUS = 1
		IO_APIC = 2
		IO_INTERRUPT_ASSIGNMENT = 3
		LOCAL_INTERRUPT_ASSIGNMENT = 4
	end enum
		
	
	type cte_processor field=1
		entry_type as ubyte
		local_apic_id as ubyte
		local_apic_version as ubyte
		flags as ubyte
		signature as zstring*4
		feature_flags as uinteger
		reserved as ulongint
	end type
	
	type cte_bus field=1
		entry_type as ubyte
		bus_id as ubyte
		type_string as zstring*6
	end type
	
	type cte_io_apic field=1
		entry_type as ubyte
		id as ubyte
		version as ubyte
		flags as ubyte
		address as uinteger
	end type
	
	type cte_io_interrupt_assignment field=1
		entry_type as ubyte
		interrupt_type as ubyte
		flags as ushort
		bus_id as ubyte
		bus_irq as ubyte
		apic_id as ubyte
		apic_int as ubyte
	end type
	
	type cte_local_interrupt_assignment field=1
		entry_type as ubyte
		interrupt_type as ubyte
		flags as ushort
		bus_id as ubyte
		bus_irq as ubyte
		apic_id as ubyte
		apic_int as ubyte
	end type

	declare sub init ()
end namespace
