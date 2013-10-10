#pragma once
'' multiboot.bi - translated by Stefan Schmidt for The FROST Project
    /'  multiboot.h - Multiboot header file.  '/
    /'  Copyright (C) 1999,2003,2007,2008,2009,2010  Free Software Foundation, Inc.
     '
     '  Permission is hereby granted, free of charge, to any person obtaining a copy
     '  of this software and associated documentation files (the "Software"), to
     '  deal in the Software without restriction, including without limitation the
     '  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
     '  sell copies of the Software, and to permit persons to whom the Software is
     '  furnished to do so, subject to the following conditions:
     '
     '  The above copyright notice and this permission notice shall be included in
     '  all copies or substantial portions of the Software.
     '
     '  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
     '  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
     '  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL ANY
     '  DEVELOPER OR DISTRIBUTOR BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
     '  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR
     '  IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
     '/
    
    /' How many bytes from the start of the file we search for the header.  '/
    #define MULTIBOOT_SEARCH                        8192
    #define MULTIBOOT_HEADER_ALIGN                  4
    
    /' The magic field should contain this.  '/
    #define MULTIBOOT_HEADER_MAGIC                  &h1BADB002
    
    /' This should be in %eax.  '/
    #define MULTIBOOT_BOOTLOADER_MAGIC              &h2BADB002
    
    /' Alignment of multiboot modules.  '/
    #define MULTIBOOT_MOD_ALIGN                     &h00001000
    
    /' Alignment of the multiboot info typeure.  '/
    #define MULTIBOOT_INFO_ALIGN                    &h00000004
    
    /' Flags set in the 'flags' member of the multiboot header.  '/
    
    /' Align all boot modules on i386 page (4KB) boundaries.  '/
    #define MULTIBOOT_PAGE_ALIGN                    &h00000001
    
    /' Must pass memory information to OS.  '/
    #define MULTIBOOT_MEMORY_INFO                   &h00000002
    
    /' Must pass video information to OS.  '/
    #define MULTIBOOT_VIDEO_MODE                    &h00000004
    
    /' This flag indicates the use of the address fields in the header.  '/
    #define MULTIBOOT_AOUT_KLUDGE                   &h00010000
    
    /' Flags to be set in the 'flags' member of the multiboot info typeure.  '/
    
    /' is there basic lower/upper memory information? '/
    #define MULTIBOOT_INFO_MEMORY                   &h00000001
    /' is there a boot device set? '/
    #define MULTIBOOT_INFO_BOOTDEV                  &h00000002
    /' is the command-line defined? '/
    #define MULTIBOOT_INFO_CMDLINE                  &h00000004
    /' are there modules to do something with? '/
    #define MULTIBOOT_INFO_MODS                     &h00000008
    
    /' These next two are mutually exclusive '/
    
    /' is there a symbol table loaded? '/
    #define MULTIBOOT_INFO_AOUT_SYMS                &h00000010
    /' is there an ELF section header table? '/
    #define MULTIBOOT_INFO_ELF_SHDR                 &h00000020
    
    /' is there a full memory map? '/
    #define MULTIBOOT_INFO_MEM_MAP                  &h00000040
    
    /' Is there drive info?  '/
    #define MULTIBOOT_INFO_DRIVE_INFO               &h00000080
    
    /' Is there a config table?  '/
    #define MULTIBOOT_INFO_CONFIG_TABLE             &h00000100
    
    /' Is there a boot loader name?  '/
    #define MULTIBOOT_INFO_BOOT_LOADER_NAME         &h00000200
    
    /' Is there a APM table?  '/
    #define MULTIBOOT_INFO_APM_TABLE                &h00000400
    
    /' Is there video information?  '/
    #define MULTIBOOT_INFO_VBE_INFO                 &h00000800
    #define MULTIBOOT_INFO_FRAMEBUFFER_INFO         &h00001000
    
    #ifndef ASM_FILE
    
    type multiboot_uint8_t as uinteger<8>
    type multiboot_uint16_t as uinteger<16>
    type multiboot_uint32_t as uinteger<32>
    type multiboot_uint64_t as uinteger<64>
    
    type multiboot_header
      /' Must be MULTIBOOT_MAGIC - see above.  '/
      dim as multiboot_uint32_t magic
     
      /' Feature flags.  '/
      dim as multiboot_uint32_t flags
     
      /' The above fields plus this one must equal 0 mod 2^32. '/
      dim as multiboot_uint32_t checksum
     
      /' These are only valid if MULTIBOOT_AOUT_KLUDGE is set.  '/
      dim as multiboot_uint32_t header_addr
      dim as multiboot_uint32_t load_addr
      dim as multiboot_uint32_t load_end_addr
      dim as multiboot_uint32_t bss_end_addr
      dim as multiboot_uint32_t entry_addr
     
      /' These are only valid if MULTIBOOT_VIDEO_MODE is set.  '/
      dim as multiboot_uint32_t mode_type
      dim as multiboot_uint32_t width
      dim as multiboot_uint32_t height
      dim as multiboot_uint32_t depth
    end type
    
    /' The symbol table for a.out.  '/
    type multiboot_aout_symbol_table
      dim as multiboot_uint32_t tabsize
      dim as multiboot_uint32_t strsize
      dim as multiboot_uint32_t addr
      dim as multiboot_uint32_t reserved
    end type
    type multiboot_aout_symbol_table_t as multiboot_aout_symbol_table
    
    /' The section header table for ELF.  '/
    type multiboot_elf_section_header_table
      dim as multiboot_uint32_t num
      dim as multiboot_uint32_t size
      dim as multiboot_uint32_t addr
      dim as multiboot_uint32_t shndx
    end type
    type multiboot_elf_section_header_table_t as multiboot_elf_section_header_table
    
    type multiboot_info
      /' Multiboot info version number '/
      dim as multiboot_uint32_t flags
     
      /' Available memory from BIOS '/
      dim as multiboot_uint32_t mem_lower
      dim as multiboot_uint32_t mem_upper
     
      /' "root" partition '/
      dim as multiboot_uint32_t boot_device
     
      /' Kernel command line '/
      dim as multiboot_uint32_t cmdline
     
      /' Boot-Module list '/
      dim as multiboot_uint32_t mods_count
      dim as multiboot_uint32_t mods_addr
     
      union
        dim as multiboot_aout_symbol_table_t aout_sym
        dim as multiboot_elf_section_header_table_t elf_sec
      end union
     
      /' Memory Mapping buffer '/
      dim as multiboot_uint32_t mmap_length
      dim as multiboot_uint32_t mmap_addr
     
      /' Drive Info buffer '/
      dim as multiboot_uint32_t drives_length
      dim as multiboot_uint32_t drives_addr
     
      /' ROM configuration table '/
      dim as multiboot_uint32_t config_table
     
      /' Boot Loader Name '/
      dim as multiboot_uint32_t boot_loader_name
     
      /' APM table '/
      dim as multiboot_uint32_t apm_table
     
      /' Video '/
      dim as multiboot_uint32_t vbe_control_info
      dim as multiboot_uint32_t vbe_mode_info
      dim as multiboot_uint16_t vbe_mode
      dim as multiboot_uint16_t vbe_interface_seg
      dim as multiboot_uint16_t vbe_interface_off
      dim as multiboot_uint16_t vbe_interface_len
     
      dim as multiboot_uint64_t framebuffer_addr
      dim as multiboot_uint32_t framebuffer_pitch
      dim as multiboot_uint32_t framebuffer_width
      dim as multiboot_uint32_t framebuffer_height
      dim as multiboot_uint8_t framebuffer_bpp
    #define MULTIBOOT_FRAMEBUFFER_TYPE_INDEXED 0
    #define MULTIBOOT_FRAMEBUFFER_TYPE_RGB     1
    #define MULTIBOOT_FRAMEBUFFER_TYPE_EGA_TEXT     2
      dim as multiboot_uint8_t framebuffer_type
      union
        type
          dim as multiboot_uint32_t framebuffer_palette_addr
          dim as multiboot_uint16_t framebuffer_palette_num_colors
        end type
        type
          dim as multiboot_uint8_t framebuffer_red_field_position
          dim as multiboot_uint8_t framebuffer_red_mask_size
          dim as multiboot_uint8_t framebuffer_green_field_position
          dim as multiboot_uint8_t framebuffer_green_mask_size
          dim as multiboot_uint8_t framebuffer_blue_field_position
          dim as multiboot_uint8_t framebuffer_blue_mask_size
        end type
      end union
    end type
    type multiboot_info_t as multiboot_info
    
    type multiboot_color
      dim as multiboot_uint8_t red
      dim as multiboot_uint8_t green
      dim as multiboot_uint8_t blue
    end type
    
    type multiboot_mmap_entry field=1
      dim as multiboot_uint32_t size
      dim as multiboot_uint64_t addr
      dim as multiboot_uint64_t len
    #define MULTIBOOT_MEMORY_AVAILABLE              1
    #define MULTIBOOT_MEMORY_RESERVED               2
    #define MULTIBOOT_MEMORY_ACPI_RECLAIMABLE       3
    #define MULTIBOOT_MEMORY_NVS                    4
    #define MULTIBOOT_MEMORY_BADRAM                 5
      dim as multiboot_uint32_t type
    end type
    type multiboot_memory_map_t as multiboot_mmap_entry
    
    type multiboot_mod_list
      /' the memory used goes from bytes 'mod_start' to 'mod_end-1' inclusive '/
      dim as multiboot_uint32_t mod_start
      dim as multiboot_uint32_t mod_end
     
      /' Module command line '/
      dim as multiboot_uint32_t cmdline
     
      /' padding to take it to 16 bytes (must be zero) '/
      dim as multiboot_uint32_t pad
    end type
    type multiboot_module_t as multiboot_mod_list
    
    /' APM BIOS info.  '/
    type multiboot_apm_info
      dim as multiboot_uint16_t version
      dim as multiboot_uint16_t cseg
      dim as multiboot_uint32_t offset
      dim as multiboot_uint16_t cseg_16
      dim as multiboot_uint16_t dseg
      dim as multiboot_uint16_t flags
      dim as multiboot_uint16_t cseg_len
      dim as multiboot_uint16_t cseg_16_len
      dim as multiboot_uint16_t dseg_len
    end type
    
    #endif /' ! ASM_FILE '/
