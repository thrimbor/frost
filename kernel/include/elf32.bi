#pragma once

namespace elf32
    type Elf32_Addr  as uinteger
    type Elf32_Half  as ushort
    type ELF32_Off   as uinteger
    type Elf32_Sword as integer
    type Elf32_Word  as uinteger
    type Elf32_Uchar as ubyte
    
    const ELF_MAGIC as uinteger = &h464C457F       '' &h7F, 'E', 'L', 'F'
    
    const ELF_CLASS_NONE as ubyte = &h00
    const ELF_CLASS_32 as ubyte = &h01             '' 32bit file
    const ELF_CLASS_64 as ubyte = &h02             '' 64bit file
    
    const ELF_DATA_NONE as ubyte = &h00
    const ELF_DATA_2LSB as ubyte = &h01
    const ELF_DATA_2MSB as ubyte = &h02
    
    type ELF_IDENT_HEADER field=1
        EI_MAGIC as uinteger
        EI_CLASS as ubyte                          '' 32 or 64 bit?
        EI_DATA as ubyte                           '' Little or Big Endian?
        EI_VERSION as ubyte                        '' same as e_version
        EI_PAD as uinteger                         '' reserved (zero)
        EI_PAD2 as uinteger                        '' reserved (zero)
        EI_NIDENT as ubyte                         '' size of the IDENT_HEADER
    end type
    
    '' for 32bit Processors:
    '   e_ident.EI_CLASS = ELF_CLASS_32
    '   e_ident.EI_DATA = ELF_DATA_2LSB
    '   e_machine = ELF_EM_386
    
    const ELF_ET_NONE as ushort = &h0000           '' no type
    const ELF_ET_REL as ushort = &h0001            '' relocatable
    const ELF_ET_EXEC as ushort = &h0002           '' executeable
    const ELF_ET_DYN as ushort = &h0003            '' Shared-Object-File
    const ELF_ET_CORE as ushort = &h0004           '' Corefile
    const ELF_ET_LOPROC as ushort = &hFF00         '' Processor-specific
    const ELF_ET_HIPROC as ushort = &h00FF         '' Processor-specific
    
    const ELF_EM_NONE as ushort = &h0000           '' no type
    const ELF_EM_M32 as ushort = &h0001            '' AT&T WE 32100
    const ELF_EM_SPARC as ushort = &h0002          '' SPARC
    const ELF_EM_386 as ushort = &h0003            '' Intel 80386
    const ELF_EM_68K as ushort = &h0004            '' Motorola 68000
    const ELF_EM_88K as ushort = &h0005            '' Motorola 88000
    const ELF_EM_860 as ushort = &h0007            '' Intel 80860
    const ELF_EM_MIPS as ushort = &h0008           '' MIPS RS3000
    
    const ELF_EV_NONE as uinteger = &h00           '' invalid version
    const ELF_EV_CURRENT as uinteger = &h01        '' current version
    
    type Elf32_Ehdr field=1
        e_ident     as ELF_IDENT_HEADER            '' IDENT-HEADER (see above)
        e_type      as Elf32_Half                  '' type of the ELF-file (relocatable, executeable, shared-object...)
        e_machine   as Elf32_Half                  '' processor-type
        e_version   as Elf32_Word                  '' ELF-version
        e_entry     as Elf32_Addr                  '' virtual address of the entrypoint
        e_phoff     as Elf32_Off                   '' offset of the program-header. zero if no program-header exists
        e_shoff     as Elf32_Off                   '' offset of the section-header. zero if no section-header exists
        e_flags     as Elf32_Word                  '' processor-specific flags
        e_ehsize    as Elf32_Half                  '' size of the ELF-header
        e_phentsize as Elf32_Half                  '' size of one program-header entry
        e_phnum     as Elf32_Half                  '' number of entries in the program-header. zero if no program-header exists
        e_shentsize as Elf32_Half                  '' size of one section-header entry
        e_shnum     as Elf32_Half                  '' number of entries in the section-header. zero if no section-header exists
        e_shstrndex as Elf32_Half                  '' tells us which entry of the section-header is linked to the String-Table
    end type
    
    const ELF_PT_NULL as uinteger = &h00           '' invalid segment
    const ELF_PT_LOAD as uinteger = &h01           '' loadable segment
    const ELF_PT_DYNAMIC as uinteger = &h02        '' dynamic segment
    const ELF_PT_INTERP as uinteger = &h03         '' position of a zero-terminated string, which tells the interpreter
    const ELF_PT_NOTE as uinteger = &h04           '' universal segment
    const ELF_PT_SHLIB as uinteger = &h05          '' shared lib
    const ELF_PT_PHDIR as uinteger = &h06          '' tells position and size of the program-header
    const ELF_PT_LOPROC as uinteger = &h70000000   '' reserved
    const ELF_PT_HIPROC as uinteger = &h7FFFFFFF   '' reserved
    
    const ELF_PF_X as uinteger = &h01              '' executeable segment
    const ELF_PF_W as uinteger = &h02              '' writeable segment
    const ELF_PF_R as uinteger = &h04              '' readable segment
    
    type Elf32_Phdr field=1
        p_type as Elf32_Word                       '' type of the segment (see constants above)
        p_offset as Elf32_Off                      '' offset of the segment (in the file)
        p_vaddr as Elf32_Addr                      '' virtual address to which we should copy the segment
        p_paddr as Elf32_Addr                      '' physical address
        p_filesz as Elf32_Word                     '' size of the segment in the file
        p_memsz as Elf32_Word                      '' size of the segment in memory
        p_flags as Elf32_Word                      '' flags (combination of constants above)
        p_align as Elf32_Word                      '' alignment. if zero or one, then no alignment is needed, otherwise the alignment has to be a power of two
    end type
end namespace
