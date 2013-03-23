#pragma once

#include "elf32.bi"
#include "process.bi"

namespace elf
    declare function header_check (header as elf32.Elf32_Ehdr ptr) as integer
    declare function load_image (process as process_type ptr, image as uinteger, size as uinteger) as boolean
end namespace
