/'
 ' FROST x86 microkernel
 ' Copyright (C) 2010-2016  Stefan Schmidt
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

#include "address_space.bi"
#include "pmm.bi"
#include "kmm.bi"
#include "video.bi"

DEFINE_LIST(address_space_area)

constructor address_space_area (address as any ptr, pages as uinteger, flags as uinteger = 0, description as zstring ptr = nullptr)
	this.address = address
	this.pages = pages
	this.flags = flags
	this.description = description
end constructor

operator address_space_area.new (size as uinteger) as any ptr
	return kmalloc(size)
end operator

operator address_space_area.delete (buffer as any ptr)
	kfree(buffer)
end operator

function address_space.allocate_area (pages as uinteger, flags as uinteger = 0, description as zstring ptr = nullptr) as address_space_area ptr
	''  1. search the list of areas for a free spot
	''  2. create a new area and insert it in the list
	''  3. return the address of the area
	
	dim min_addr as uinteger = &h40000000
	dim insert_after as Listtype(address_space_area) ptr = @this.areas
	
	list_foreach(h, this.areas)
		dim x as address_space_area ptr = h->get_owner()
		
		insert_after = h
		
		'' Is the hole big enough?
		if (x->address > min_addr + pages) then
			list_foreach_exit
		end if
		
		'' try the next hole
		min_addr = cuint(x->address) + x->pages * PAGE_SIZE
	list_next(h)
	
	'' Did we walk through the list and didn't find a hole yet?
	if ((min_addr <> &h40000000) and (insert_after <> @this.areas)) then
		'' check if there's space at the end
		dim x as address_space_area ptr = this.areas.get_prev()->get_owner()
		if (x->address + x->pages*PAGE_SIZE < &hFFFFFFFF - pages) then
			min_addr = cuint(x->address) + x->pages*PAGE_SIZE
			insert_after = this.areas.get_prev()
		else
			'' Nope, nothing's free
			return 0
		end if
	end if
	
	'' Create new struct
	dim area as address_space_area ptr = new address_space_area(cast(any ptr, min_addr), pages, flags, description)
	
	'' insert it
	insert_after->insert_after(@area->list)
	
	'' return the area address
	return area
end function

sub address_space.insert_area (area as address_space_area ptr)
	assert(area->pages <> 0)
	dim insert_after as Listtype(address_space_area) ptr = @this.areas
	
	list_foreach(h, this.areas)
		dim x as address_space_area ptr = h->get_owner()
		
		if (x->address > area->address) then
			'' check for overlaps
			assert(area->address+area->pages*PAGE_SIZE <= x->address)
			
			list_foreach_exit
		else
			'' check for overlaps
			assert(x->address+x->pages*PAGE_SIZE <= area->address)
		end if
		
		insert_after = h
	list_next(h)
	
	insert_after->insert_after(@area->list)
	
end sub
