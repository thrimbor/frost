#pragma once
#include "multiboot.bi"

declare sub load_init_module (mbinfo as multiboot_info ptr)
declare sub load_module (multiboot_module as multiboot_module_t ptr)
