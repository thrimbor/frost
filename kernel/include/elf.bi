#include once "elf32.bi"

namespace elf
    declare function header_check (header as elf32.Elf32_Ehdr ptr) as integer
end namespace
