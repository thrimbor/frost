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

#include "modules.bi"
#include "multiboot.bi"
#include "process.bi"
#include "elf.bi"
#include "kernel.bi"
#include "panic.bi"
#include "vmm.bi"
#include "pmm.bi"
#include "video.bi"

sub load_init_module (mbinfo as multiboot_info ptr)
	'' if no modules are available, we have a problem
	if (mbinfo->mods_count = 0) then
		panic_error(!"No init-module available.\n")
	end if
	
	load_module(cast(multiboot_module_t ptr, mbinfo->mods_addr))

	'' we loaded the module, so remove it from the list
	mbinfo->mods_addr += sizeof(multiboot_module_t)
	mbinfo->mods_count -= 1
end sub

'' TODO: the cmdline should be given to the module somehow
sub load_module (multiboot_module as multiboot_module_t ptr)
	dim v_multiboot_module as multiboot_module_t ptr

	'' map the module structure
	v_multiboot_module = vmm_kernel_automap(multiboot_module, sizeof(multiboot_module_t))
	if (v_multiboot_module = 0) then
		panic_error(!"Could not map the module-structure of the module\n")
	end if
	
	'' map the image
	dim size as uinteger = v_multiboot_module->mod_end - v_multiboot_module->mod_start
	dim v_image as uinteger = cuint(vmm_kernel_automap(cast(any ptr, v_multiboot_module->mod_start), size))
	
	dim process as process_type ptr
	process = process_create(nullptr)
	
	if (process = nullptr) then
		panic_error(!"Could not create init-process!\n")
	end if
	
	if (not(elf.load_image(process, v_image, size))) then
		panic_error(!"Could not load the init-module!")
	end if
	
	thread_activate(process->threads)
	
	'' unmap the image, we don't need it any longer
	vmm_kernel_unmap(cast(any ptr, v_image), size)
	'' physically free the space occupied by the image
	pmm_free(cast(any ptr, v_multiboot_module->mod_start), num_pages(size))
	'' unmap the module struct
	vmm_kernel_unmap(v_multiboot_module, sizeof(multiboot_module_t))
end sub
