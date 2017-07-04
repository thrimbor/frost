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

#include "pmm.bi"
#include "vmm.bi"
#include "mem.bi"
#include "kernel.bi"
#include "multiboot.bi"
#include "spinlock.bi"
#include "panic.bi"

'' the amount of free memory
dim shared free_mem as uinteger = 0
dim shared total_mem as uinteger = 0

function pmm_get_total () as uinteger
	return total_mem
end function

function pmm_get_free () as uinteger
	return free_mem
end function

function pmm_intersect (page_addr as addr_t, area_start as addr_t, area_end as addr_t) as boolean
	if ((area_start >= page_addr) and (area_start <= page_addr+PAGE_SIZE)) then return true
	if ((area_end >= page_addr) and (area_end <= page_addr+PAGE_SIZE)) then return true
	if ((area_start <= page_addr) and (area_end >= page_addr+PAGE_SIZE)) then return true

	return false
end function

sub pmm_init (mbinfo as multiboot_info ptr, zone as uinteger)
	'' 1. all memory is used by default
	'' 2. all free areas are put on the stack, but checked against reserved areas
	'' 3. reserved are:
	''    - memory used by the kernel code
	''    - video memory
	''    - modules and their cmdlines
	'' done

	'' initialization is slow, usage is fast (with a bitmap it's exactly the opposite)
	'' 1. mark the whole memory as used
	'' 2. free the memory marked as free in the memory-map
	'' 3. mark the whole memory used by the kernel as used
	'' 4. mark the video memory as used
	'' 5. mark the modules and their cmdline as used

	if ((mbinfo->flags and MULTIBOOT_INFO_MEM_MAP) = 0) then
		panic_error(!"Memory map not available!\n")
	end if

	assert((vmm_is_paging_ready() and cbool(zone = PMM_ZONE_NORMAL)) or ((not vmm_is_paging_ready()) and cbool(zone = PMM_ZONE_DMA24)))

	if (zone = PMM_ZONE_DMA24) then pmm_init_dma24()

	dim mmap as multiboot_mmap_entry ptr = cast(multiboot_mmap_entry ptr, mbinfo->mmap_addr)
	dim mmap_end as multiboot_mmap_entry ptr = cast(multiboot_mmap_entry ptr, (mbinfo->mmap_addr + mbinfo->mmap_length))

	'' free the memory listed in the memory-map
	while (mmap < mmap_end)
		'' only free regions that are marked as available
		if (mmap->type = MULTIBOOT_MEMORY_AVAILABLE) then
			'' don't free memory over 4GB, needs to be fixed to properly work on 64bit
			if (cuint((mmap->addr shr 32) and &hFFFFFFFF) = 0) then
				'' free each block of the region
				for addr as addr_t = mmap->addr to (mmap->addr+mmap->len-1) step PAGE_SIZE
					if (zone = PMM_ZONE_DMA24) and (addr >= 16*1024*1024) then exit for

					if (zone = PMM_ZONE_NORMAL) and (addr < 16*1024*1024) then continue for

					total_mem += PAGE_SIZE

					'' check if the block contains used memory
					'' does the block contain kernel memory?
					if (pmm_intersect(addr, caddr(kernel_start), caddr(kernel_end))) then continue for

					if (pmm_intersect(addr, mbinfo->cmdline, mbinfo->cmdline+PAGE_SIZE)) then continue for

					'' does the block contain video memory?
					if (pmm_intersect(addr, &hB8000, &hB8000+PAGE_SIZE)) then continue for

					'' iterate over the module list
					dim module_ptr as multiboot_mod_list ptr = cast(any ptr, mbinfo->mods_addr)

					for counter as uinteger = 1 to mbinfo->mods_count
						if (pmm_intersect(addr, module_ptr[counter-1].mod_start, module_ptr[counter-1].mod_end)) then
							continue for, for
						end if

						if (pmm_intersect(addr, module_ptr[counter-1].cmdline, module_ptr[counter-1].cmdline+PAGE_SIZE)) then
							continue for, for
						end if
					next

                    '' &h1000 is reserved for the SMP trampoline-code
                    if (addr = &h1000) then continue for

					'' free one block at a time
					if (zone = PMM_ZONE_NORMAL) then
						pmm_free_normal(cast(any ptr, cuint(addr)))
						free_mem += PAGE_SIZE
					elseif (zone = PMM_ZONE_DMA24) then
						pmm_free_dma24(cast(any ptr, cuint(addr)))
						free_mem += PAGE_SIZE
					end if
				next
			end if
		end if
		'' go to the next entry of the map
		mmap = cast(multiboot_mmap_entry ptr, cuint(mmap)+mmap->size+sizeof(multiboot_uint32_t))
	wend
end sub

function pmm_alloc (zone as uinteger = PMM_ZONE_NORMAL) as any ptr
	dim ret as any ptr = nullptr

	select case (zone)
		case PMM_ZONE_NORMAL:
			'' try to satisfy the request from the normal-zone
			ret = pmm_alloc_normal()
			if (ret = nullptr) then
				'' if it didn't work, fall through to the DMA24-zone
				ret = pmm_alloc(PMM_ZONE_DMA24)
			end if
		case PMM_ZONE_DMA24:
			ret = pmm_alloc_dma24()
		case else:
			panic_error(!"PMM: Invalid zone specification!\n")
	end select

	if (ret <> nullptr) then free_mem -= PAGE_SIZE
	return ret
end function

sub pmm_free (addr as any ptr)
	if (cuint(addr) < 16*1024*1024) then
		pmm_free_dma24(addr)
	else
		pmm_free_normal(addr)
	end if
	free_mem += PAGE_SIZE
end sub
