/'
 ' FROST x86 microkernel
 ' Copyright (C) 2010-2017  Stefan Schmidt
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

#include "acpi.bi"
#include "mem.bi"
#include "kernel.bi"
#include "video.bi"

function validate_rsdp (addr as rsdp_descriptor ptr) as boolean
    dim rsdp_b as ubyte ptr = cast(ubyte ptr, addr)
    dim checksum as ubyte = 0
    for i as uinteger = 0 to sizeof(rsdp_descriptor)-1
        checksum += rsdp_b[i]
    next

    if (checksum <> 0) then
        printk(LOG_ERR COLOR_GREEN "ACPI: " COLOR_RED !"checksum mismatch in RSDP descriptor\n" COLOR_RESET)
        return false
    end if

    if (addr->revision = 0) then
        printk(LOG_INFO COLOR_GREEN "ACPI: " COLOR_RESET !"RSDP descriptor found\n")
        return true
    end if

    checksum = 0
    for i as uinteger = sizeof(rsdp_descriptor) to sizeof(rsdp_descriptor_20)-1
        checksum += rsdp_b[i]
    next

    if (checksum <> 0) then
        printk(LOG_ERR COLOR_GREEN "ACPI: " COLOR_RED !"checksum mismatch in extended RSDP descriptor\n" COLOR_RESET)
        return false
    end if

    printk(LOG_INFO COLOR_GREEN "ACPI: " COLOR_RESET !"extended RSDP descriptor found\n")
    return true
end function

function find_rsdp_in_area (start as uinteger, size as uinteger) as rsdp_descriptor ptr
	dim rsdp as rsdp_descriptor ptr = cast(rsdp_descriptor ptr, start)

	while (cuint(rsdp) < (start + size))
		'' signature found
		if (memcmp(rsdp, strptr("RSD PTR "), 8) = 0) then
			'' check checksum, sum of all bytes must be zero
            if (validate_rsdp(rsdp)) then
				'' structure seems valid, return it
				return rsdp
			end if
		end if

		'' not found yet, search some more
		'' the structure is located on a 16-byte boundary
		rsdp = cast(rsdp_descriptor ptr, cuint(rsdp)+16)
	wend

	'' structure not found
	return nullptr
end function

function find_rsdp as rsdp_descriptor ptr
	dim rsdp as rsdp_descriptor ptr

	dim ebda_addr as uinteger = *cast(ushort ptr, &h040E)
	ebda_addr shl= 4

	if (ebda_addr + &h400 < &h100000) then
		rsdp = find_rsdp_in_area(ebda_addr, &h400)
		if (rsdp <> nullptr) then return rsdp
	end if

	rsdp = find_rsdp_in_area(&h000E0000, &h20000)
	'if (rsdp <> nullptr) then return rsdp

	'rsdp = find_floating_pointer_in_area(&hF0000, &h10000)
	return rsdp
end function

sub parse_madt (p as any ptr)
	dim length as uinteger = (*cast(uinteger ptr, p+&h04)) - sizeof(sdt_header) - 8
	dim records as any ptr = p+&h2C

	while (records <= p+length)
		dim entry_type as ubyte = *cast(ubyte ptr, records)
		dim record_length as ubyte = *cast(ubyte ptr, records+1)

		if (entry_type = 0) then
            dim flags as uinteger = *cast(uinteger ptr, records+4)
            if (flags = 1) then
			     printk(LOG_INFO COLOR_GREEN "ACPI: " COLOR_RESET !"Processor found!\n")
            end if
		elseif (entry_type = 1) then
			printk(LOG_INFO COLOR_GREEN "ACPI: " COLOR_RESET !"I/O APIC found!\n")
		end if

		records += record_length
	wend
end sub

'' TODO: print some more info
sub acpi_init ()
	dim rsdp as rsdp_descriptor ptr = find_rsdp()

	if (rsdp = nullptr) then return

	printk(LOG_INFO COLOR_GREEN "ACPI: " COLOR_RESET !"found ACPI RSDP descriptor at %X\n", cuint(rsdp))
	printk(LOG_INFO COLOR_GREEN "ACPI: " COLOR_RESET !"revision is %u\n", cuint(rsdp->revision))
	printk(LOG_INFO COLOR_GREEN "ACPI: " COLOR_RESET !"ACPI OEMID: %c%c%c%c%c%c\n", rsdp->oemid[0], rsdp->oemid[1], rsdp->oemid[2], rsdp->oemid[3], rsdp->oemid[4], rsdp->oemid[5])

	dim rsdt as sdt_header ptr = cast(sdt_header ptr, rsdp->rsdt_address)
	'' TODO: check RSDT checksum

	dim num_entries as uinteger = (rsdt->length - sizeof(sdt_header)) \ 4
	dim entries_ptr as uinteger ptr = cast(any ptr, rsdt) + sizeof(sdt_header)

	for i as uinteger = 0 to num_entries-1
		dim table_ptr as sdt_header ptr = cast(sdt_header ptr, entries_ptr[i])

		printk(LOG_INFO COLOR_GREEN "ACPI: " COLOR_RESET !"Table type: %c%c%c%c\n", table_ptr->signature[0], table_ptr->signature[1], table_ptr->signature[2], table_ptr->signature[3])

		if (table_ptr->signature[0] = asc("A") and _
				table_ptr->signature[1] = asc("P") and _
				table_ptr->signature[2] = asc("I") and _
				table_ptr->signature[3] = asc("C")) then
			parse_madt(table_ptr)
		end if
	next

end sub
