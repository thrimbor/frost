#include once "elf.bi"
#include once "elf32.bi"

namespace elf
    function header_check (header as elf32.Elf32_Ehdr ptr) as integer
        if (not(header->e_ident.EI_MAGIC = elf32.ELF_MAGIC)) then return 1
        if (not(header->e_type = elf32.ELF_ET_EXEC)) then return 2
        if (not(header->e_machine = elf32.ELF_EM_386)) then return 3
        if (not(header->e_ident.EI_CLASS = elf32.ELF_CLASS_32)) then return 4
        if (not(header->e_ident.EI_DATA = elf32.ELF_DATA_2LSB)) then return 5
        if (not(header->e_version = elf32.ELF_EV_CURRENT)) then return 6
        return 0
    end function
end namespace
