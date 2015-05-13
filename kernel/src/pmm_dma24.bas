/'
 ' FROST x86 microkernel
 ' Copyright (C) 2010-2015  Stefan Schmidt
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
#include "spinlock.bi"
#include "kernel.bi"
#include "mem.bi"
#include "panic.bi"

'' TODO: on x64, we can test a whole uinteger<64> at once - so make this dynamic!

'' NOTE: As long as we just allocate with PAGE_SIZE-granularity, we
''       could use a 'start looking here' pointer to reduce allocation time

const bitmap_size = 128
'' memory bitmap for 0-16MB. 0=used, 1=free
dim shared bitmap (0 to bitmap_size-1) as uinteger<32>
dim shared pmm_dma24_lock as spinlock


sub pmm_init_dma24 ()
	'' mark the whole memory as occupied
	memset(@bitmap(0), 0, bitmap_size*4)
end sub

function pmm_alloc_dma24 () as any ptr
	pmm_dma24_lock.acquire()
	
	for counter as uinteger = lbound(bitmap) to ubound(bitmap)
		if (bitmap(counter) = 0) then continue for
		
		for bitcounter as uinteger = 0 to 31
			if (bitmap(counter) and (1 shl bitcounter)) then
				'' this page is free
				'' mark used
				bitmap(counter) and= (not(1 shl bitcounter))
				'' return page address
				pmm_dma24_lock.release()
				return cast(any ptr, (counter*32 + bitcounter)*PAGE_SIZE)
			end if
		next
	next
	
	'' no free page found?
	pmm_dma24_lock.release()
	panic_error("PMM_DMA24: Out of memory!\n")
	return nullptr
end function

sub pmm_free_dma24 (page as any ptr)
	pmm_dma24_lock.acquire()
	
	dim p as uinteger = cuint(page) \ PAGE_SIZE
	
	dim index as uinteger = p shr 5
	dim modifier as uinteger<32> = (1 shl (p mod 32))
	
	assert((bitmap(index) and modifier) = 0) '' make sure that the page really was occupied
	
	bitmap(index) or= modifier
	
	pmm_dma24_lock.release()
end sub
