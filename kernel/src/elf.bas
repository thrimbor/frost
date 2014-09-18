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

#include "elf.bi"
#include "elf32.bi"
#include "process.bi"
#include "thread.bi"
#include "pmm.bi"
#include "mem.bi"
#include "panic.bi"

function elf_header_check (header as Elf32_Ehdr ptr) as integer
	'' check for the magic value (&h7F, 'E', 'L', 'F')
	if ((header->e_ident.EI_MAGIC(0) <> &h7F) or _
		(header->e_ident.EI_MAGIC(1) <> &h45) or _
		(header->e_ident.EI_MAGIC(2) <> &h4C) or _
		(header->e_ident.EI_MAGIC(3) <> &h46)) then return 1
			
	if (header->e_type <> ELF_ET_EXEC) then return 2
	if (header->e_machine <> ELF_EM_386) then return 3
	if (header->e_ident.EI_CLASS <> ELF_CLASS_32) then return 4
	if (header->e_ident.EI_DATA <> ELF_DATA_2LSB) then return 5
	if (header->e_version <> ELF_EV_CURRENT) then return 6
	return 0
end function

function elf_load_image (process as process_type ptr, image as uinteger, size as uinteger) as boolean
	dim header as Elf32_Ehdr ptr = cast(Elf32_Ehdr ptr, image)
	
	if (size < sizeof(Elf32_Ehdr)) then return false
	
	if (elf_header_check(header) > 0) then return false
	
	'' the only module loaded by this code is init, so we reserve a stack here
	'' every other program has to get it's stack from somewhere else
	dim module_stack as any ptr = pmm_alloc(1)
	vmm_map_page(@process->context, cast(any ptr, &hFFFFF000), module_stack, VMM_FLAGS.USER_DATA)
	'' create the thread
	thread_create(process, cast(any ptr, header->e_entry), cast(any ptr, &hFFFFF000))

	'' pointer to the first program header
	dim program_header as Elf32_Phdr ptr = cast(Elf32_Phdr ptr, cuint(header) + header->e_phoff)
	
	dim min_addr as uinteger = &hFFFFFFFF
	dim max_addr as uinteger = 0
	
	'' determine the size of the needed memory area
	for counter as uinteger = 0 to header->e_phnum-1
		'' skip entries that are not loadable
		if (program_header[counter].p_type <> ELF_PT_LOAD) then continue for
		
		if (program_header[counter].p_vaddr < min_addr) then
			min_addr = program_header[counter].p_vaddr
		end if
		
		if (program_header[counter].p_vaddr + program_header[counter].p_memsz > max_addr) then
			max_addr = program_header[counter].p_vaddr + program_header[counter].p_memsz
		end if
	next
	
	'' calculate memory requirements
	dim pages as uinteger = (max_addr shr 12) - (min_addr shr 12) + 1
	min_addr and= VMM_PAGE_MASK
	
	'' reserve enough space for the program
	dim phys_mem as any ptr = pmm_alloc(pages)
	dim mem as any ptr = vmm_kernel_automap(phys_mem, pages*PAGE_SIZE)
	
	'' copy the program into the reserved space
	for counter as uinteger = 0 to header->e_phnum-1
		if (program_header[counter].p_type = ELF_PT_LOAD) then
			'' copy the segment
			memcpy(cast(any ptr, cuint(mem)+program_header[counter].p_vaddr - min_addr), _
				   cast(any ptr, cuint(image)+program_header[counter].p_offset), _
				   program_header[counter].p_filesz)
			'' fill the rest of the segment with zeroes (this is more efficient than using memset to clear ALL the memory)
			memset(cast(any ptr, cuint(mem)+program_header[counter].p_vaddr - min_addr + program_header[counter].p_filesz), _
				   0, _
				   program_header[counter].p_memsz - program_header[counter].p_filesz)
		end if
	next
	
	'' map the pages into the context of the process
	for counter as uinteger = 0 to pages-1
		if (not (vmm_map_page(@process->context, cast(any ptr, min_addr + counter*PAGE_SIZE), _
							  phys_mem+(counter*PAGE_SIZE), _
							  (VMM_PTE_FLAGS.WRITABLE or VMM_PTE_FLAGS.PRESENT or VMM_PTE_FLAGS.USERSPACE)))) then
			panic_error("Could not assign memory to the process")
		end if
	next
	
	'' unmap the target-memory from the kernel context
	vmm_kernel_unmap(mem, pages*PAGE_SIZE)
	
	return true
end function
