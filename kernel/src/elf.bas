#include "elf.bi"
#include "elf32.bi"
#include "process.bi"
#include "thread.bi"
#include "pmm.bi"
#include "mem.bi"
#include "panic.bi"

namespace elf
    function header_check (header as elf32.Elf32_Ehdr ptr) as integer
        if (header->e_ident.EI_MAGIC <> elf32.ELF_MAGIC) then return 1
        if (header->e_type <> elf32.ELF_ET_EXEC) then return 2
        if (header->e_machine <> elf32.ELF_EM_386) then return 3
        if (header->e_ident.EI_CLASS <> elf32.ELF_CLASS_32) then return 4
        if (header->e_ident.EI_DATA <> elf32.ELF_DATA_2LSB) then return 5
        if (header->e_version <> elf32.ELF_EV_CURRENT) then return 6
        return 0
    end function
    
    function load_image (process as process_type ptr, image as uinteger, size as uinteger) as boolean
		dim header as elf32.Elf32_Ehdr ptr = cast(elf32.Elf32_Ehdr ptr, image)
		
		if (size < sizeof(elf32.Elf32_Ehdr)) then return false
		if (header_check(header) > 0) then return false
		
		'' create the thread
		thread_create(process, cast(any ptr, header->e_entry))

		'' pointer to the first program header
		dim program_header as elf32.Elf32_Phdr ptr = cast(elf32.Elf32_Phdr ptr, cuint(header) + header->e_phoff)
		
		dim min_addr as uinteger = &hFFFFFFFF
		dim max_addr as uinteger = 0
		
		'' determine the size of the needed memory area
		for counter as uinteger = 0 to header->e_phnum-1
			'' skip entries that are not loadable
			if (program_header[counter].p_type <> elf32.ELF_PT_LOAD) then continue for
			
			if (program_header[counter].p_vaddr < min_addr) then
				min_addr = program_header[counter].p_vaddr
			end if
			
			if (program_header[counter].p_vaddr + program_header[counter].p_memsz > max_addr) then
				max_addr = program_header[counter].p_vaddr + program_header[counter].p_memsz
			end if
		next
		
		'' reserve space by reserving it with pmm.alloc and mapping it with vmm.kernel_automap
		dim pages as uinteger = (max_addr shr 12) - (min_addr shr 12) + 1
		dim dest_memory as any ptr = vmm.kernel_automap(pmm.alloc(pages), pages*pmm.PAGE_SIZE)
		min_addr and= &hFFFFF000
		
		for counter as uinteger = 0 to header->e_phnum-1
			if (program_header[counter].p_type = elf32.ELF_PT_LOAD) then
				'' copy the segment
				memcpy(cast(any ptr, cuint(dest_memory) + program_header[counter].p_vaddr - min_addr), _
					   cast(any ptr, cuint(image) + program_header[counter].p_offset), _
					   program_header[counter].p_filesz)
				'' fill the rest of the segment with zeroes
				memset(cast(any ptr, cuint(dest_memory) + program_header[counter].p_vaddr - min_addr + program_header[counter].p_filesz), _
					   0, _
					   program_header[counter].p_memsz - program_header[counter].p_filesz)
			end if
		next
		
		video.fout("\npages reserved: %I\n", pages)
		video.fout("min_addr: %hI\nmax_addr: %hI\n", min_addr, max_addr)
		
		'' TODO: at this point, we need to move the pages we just mapped to the context of the process
		
		'asm cli
		'asm hlt
		
		return true
	end function
end namespace
