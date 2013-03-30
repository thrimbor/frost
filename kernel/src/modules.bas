#include "modules.bi"
#include "multiboot.bi"
#include "process.bi"
#include "elf.bi"
#include "kernel.bi"
#include "panic.bi"
#include "vmm.bi"
#include "video.bi"

sub load_init_module (mbinfo as multiboot_info ptr)
	'' if no modules are available, we have a problem
	if (mbinfo->mods_count = 0) then
		panic_error(!"No init-module available.\n")
	end if
	
	
	'' load the module
	load_module(cast(multiboot_module_t ptr, mbinfo->mods_addr))

	'' we loaded the module, so remove it from the list
	mbinfo->mods_addr += sizeof(multiboot_module_t)
	mbinfo->mods_count -= 1
end sub

sub load_module (multiboot_module as multiboot_module_t ptr)
	dim v_multiboot_module as multiboot_module_t ptr

	'' map the module structure
	'v_multiboot_module = vmm.kernel_automap_page(multiboot_module)
	v_multiboot_module = vmm.kernel_automap(multiboot_module, sizeof(multiboot_module_t))
	if (v_multiboot_module = 0) then
		panic_error(!"Could not map the module-structure of the module\n")
	end if
	
	'' map the image
	dim size as uinteger = v_multiboot_module->mod_end - v_multiboot_module->mod_start
	'dim v_image as uinteger = cuint(vmm.kernel_automap_page(cast(any ptr, v_multiboot_module->mod_start)))
	dim v_image as uinteger = cuint(vmm.kernel_automap(cast(any ptr, v_multiboot_module->mod_start), size))
	
	dim process as process_type ptr
	process = process_create(nullptr)
	
	if (not(elf.load_image(process, v_image, size))) then
		panic_error(!"Could not load the init-module!")
	end if
	
	'' TODO:
	'' - free our mapped stuff and physical pages
	
end sub
