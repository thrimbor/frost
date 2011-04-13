'// multiboot2.bi - translated by darkinsanity for The FROST Project

    '// multiboot2.h - Multiboot 2 header file.
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
    
    '// How many bytes from the start of the file we search for the header.
    const MULTIBOOT_SEARCH = 32768
    const MULTIBOOT_HEADER_ALIGN = 8
    
    '// The magic field should contain this.
    const MULTIBOOT2_HEADER_MAGIC = 0xe85250d6
    
    '// This should be in %eax.
    const MULTIBOOT2_BOOTLOADER_MAGIC = 0x36d76289
    
    '// Alignment of multiboot modules.
    const MULTIBOOT_MOD_ALIGN = 0x00001000
    
    '// Alignment of the multiboot info structure.
    const MULTIBOOT_INFO_ALIGN                      0x00000008
    
    '// Flags set in the 'flags' member of the multiboot header.
    
    const MULTIBOOT_TAG_ALIGN = 8
    const MULTIBOOT_TAG_TYPE_END = 0
    const MULTIBOOT_TAG_TYPE_CMDLINE = 1
    const MULTIBOOT_TAG_TYPE_BOOT_LOADER_NAME = 2
    const MULTIBOOT_TAG_TYPE_MODULE = 3
    const MULTIBOOT_TAG_TYPE_BASIC_MEMINFO = 4
    const MULTIBOOT_TAG_TYPE_BOOTDEV = 5
    const MULTIBOOT_TAG_TYPE_MMAP = 6
    const MULTIBOOT_TAG_TYPE_VBE = 7
    const MULTIBOOT_TAG_TYPE_FRAMEBUFFER = 8
    const MULTIBOOT_TAG_TYPE_ELF_SECTIONS = 9
    const MULTIBOOT_TAG_TYPE_APM = 10
    const MULTIBOOT_TAG_TYPE_EFI32 = 11
    const MULTIBOOT_TAG_TYPE_EFI64 = 12
    const MULTIBOOT_TAG_TYPE_SMBIOS = 13
    const MULTIBOOT_TAG_TYPE_ACPI_OLD = 14
    const MULTIBOOT_TAG_TYPE_ACPI_NEW = 15
    const MULTIBOOT_TAG_TYPE_NETWORK = 16
    
    const MULTIBOOT_HEADER_TAG_END = 0
    const MULTIBOOT_HEADER_TAG_INFORMATION_REQUEST = 1
    const MULTIBOOT_HEADER_TAG_ADDRESS = 2
    const MULTIBOOT_HEADER_TAG_ENTRY_ADDRESS = 3
    const MULTIBOOT_HEADER_TAG_CONSOLE_FLAGS = 4
    const MULTIBOOT_HEADER_TAG_FRAMEBUFFER = 5
    const MULTIBOOT_HEADER_TAG_MODULE_ALIGN = 6
    
    const MULTIBOOT_ARCHITECTURE_I386 = 0
    const MULTIBOOT_ARCHITECTURE_MIPS32 = 4
    const MULTIBOOT_HEADER_TAG_OPTIONAL = 1
    
    const MULTIBOOT_CONSOLE_FLAGS_CONSOLE_REQUIRED = 1
    const MULTIBOOT_CONSOLE_FLAGS_EGA_TEXT_SUPPORTED = 2
    
    type multiboot_uint8_t as ubyte
    type multiboot_uint16_t as ushort
    type multiboot_uint32_t as uinteger
    type multiboot_uint64_t as ulongint
    
    type multiboot_header
      '// Must be MULTIBOOT_MAGIC - see above.
      dim as multiboot_uint32_t magic
     
      '// ISA
      dim as multiboot_uint32_t architecture
     
      '// Total header length.
      dim as multiboot_uint32_t header_length
     
      '// The above fields plus this one must equal 0 mod 2^32.
      dim as multiboot_uint32_t checksum
    end type
     
    type multiboot_header_tag
      dim as multiboot_uint16_t type
      dim as multiboot_uint16_t flags
      dim as multiboot_uint32_t size
    end type
     
    type multiboot_header_tag_information_request
      dim as multiboot_uint16_t type
      dim as multiboot_uint16_t flags
      dim as multiboot_uint32_t size
      dim as multiboot_uint32_t requests(0)
    end type
     
    type multiboot_header_tag_address
      dim as multiboot_uint16_t type
      dim as multiboot_uint16_t flags
      dim as multiboot_uint32_t size
      dim as multiboot_uint32_t header_addr
      dim as multiboot_uint32_t load_addr
      dim as multiboot_uint32_t load_end_addr
      dim as multiboot_uint32_t bss_end_addr
    end type
     
    type multiboot_header_tag_entry_address
      dim as multiboot_uint16_t type
      dim as multiboot_uint16_t flags
      dim as multiboot_uint32_t size
      dim as multiboot_uint32_t entry_addr
    end type
     
    type multiboot_header_tag_console_flags
      dim as multiboot_uint16_t type
      dim as multiboot_uint16_t flags
      dim as multiboot_uint32_t size
      dim as multiboot_uint32_t console_flags
    end type
     
    type multiboot_header_tag_framebuffer
      dim as multiboot_uint16_t type
      dim as multiboot_uint16_t flags
      dim as multiboot_uint32_t size
      dim as multiboot_uint32_t width
      dim as multiboot_uint32_t height
      dim as multiboot_uint32_t depth
    end type
     
    type multiboot_header_tag_module_align
      dim as multiboot_uint16_t type
      dim as multiboot_uint16_t flags
      dim as multiboot_uint32_t size
      dim as multiboot_uint32_t width
      dim as multiboot_uint32_t height
      dim as multiboot_uint32_t depth
    end type
     
    type multiboot_color
      dim as multiboot_uint8_t red
      dim as multiboot_uint8_t green
      dim as multiboot_uint8_t blue
    end type
     
    type multiboot_mmap_entry field=1
      dim as multiboot_uint64_t addr
      dim as multiboot_uint64_t len
    const MULTIBOOT_MEMORY_AVAILABLE            = 1
    const MULTIBOOT_MEMORY_RESERVED             = 2
    const MULTIBOOT_MEMORY_ACPI_RECLAIMABLE     = 3
    const MULTIBOOT_MEMORY_NVS                  = 4
    const MULTIBOOT_MEMORY_BADRAM               = 5
      dim as multiboot_uint32_t type
      dim as multiboot_uint32_t zero
    end type
    type multiboot_memory_map_t as multiboot_mmap_entry
     
    type multiboot_tag
      dim as multiboot_uint32_t type
      dim as multiboot_uint32_t size
    end type
     
    type multiboot_tag_string
      dim as multiboot_uint32_t type
      dim as multiboot_uint32_t size
      dim as byte ptr string(0)
    end type
     
    type multiboot_tag_module
      dim as multiboot_uint32_t type
      dim as multiboot_uint32_t size
      dim as multiboot_uint32_t mod_start
      dim as multiboot_uint32_t mod_end
      dim as byte ptr cmdline(0)
    end type
     
    type multiboot_tag_basic_meminfo
      dim as multiboot_uint32_t type
      dim as multiboot_uint32_t size
      dim as multiboot_uint32_t mem_lower
      dim as multiboot_uint32_t mem_upper
    end type
     
    type multiboot_tag_bootdev
      dim as multiboot_uint32_t type
      dim as multiboot_uint32_t size
      dim as multiboot_uint32_t biosdev
      dim as multiboot_uint32_t slice
      dim as multiboot_uint32_t part
    end type
     
    type multiboot_tag_mmap
      dim as multiboot_uint32_t type
      dim as multiboot_uint32_t size
      dim as multiboot_uint32_t entry_size
      dim as multiboot_uint32_t entry_version
      multiboot_mmap_entry entries(0)
    end type
     
    type multiboot_vbe_info_block
      dim as multiboot_uint8_t external_specification(512)
    end type
     
    type multiboot_vbe_mode_info_block
      dim as multiboot_uint8_t external_specification(256)
    end type
     
    type multiboot_tag_vbe
      dim as multiboot_uint32_t type
      dim as multiboot_uint32_t size
     
      dim as multiboot_uint16_t vbe_mode
      dim as multiboot_uint16_t vbe_interface_seg
      dim as multiboot_uint16_t vbe_interface_off
      dim as multiboot_uint16_t vbe_interface_len
     
      dim as multiboot_vbe_info_block vbe_control_info
      dim as multiboot_vbe_mode_info_block vbe_mode_info
    end type
     
    type multiboot_tag_framebuffer_common
      dim as multiboot_uint32_t type
      dim as multiboot_uint32_t size
     
      dim as multiboot_uint64_t framebuffer_addr
      dim as multiboot_uint32_t framebuffer_pitch
      dim as multiboot_uint32_t framebuffer_width
      dim as multiboot_uint32_t framebuffer_height
      dim as multiboot_uint8_t framebuffer_bpp
    const MULTIBOOT_FRAMEBUFFER_TYPE_INDEXED      = 0
    const MULTIBOOT_FRAMEBUFFER_TYPE_RGB          = 1
    const MULTIBOOT_FRAMEBUFFER_TYPE_EGA_TEXT     = 2
      dim as multiboot_uint8_t framebuffer_type
      dim as multiboot_uint16_t reserved
    end type
     
    type multiboot_tag_framebuffer
      dim as multiboot_tag_framebuffer_common common
     
      union
        type
          dim as multiboot_uint16_t framebuffer_palette_num_colors
          dim as type multiboot_color framebuffer_palette(0)
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
     
    type multiboot_tag_elf_sections
      dim as multiboot_uint32_t type
      dim as multiboot_uint32_t size
      dim as multiboot_uint32_t num
      dim as multiboot_uint32_t entsize
      dim as multiboot_uint32_t shndx
      dim as byte ptr sections(0)
    end type
     
    type multiboot_tag_apm
      dim as multiboot_uint32_t type
      dim as multiboot_uint32_t size
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
     
    type multiboot_tag_efi32
      dim as multiboot_uint32_t type
      dim as multiboot_uint32_t size
      dim as multiboot_uint32_t pointer
    end type
     
    type multiboot_tag_efi64
      dim as multiboot_uint32_t type
      dim as multiboot_uint32_t size
      dim as multiboot_uint64_t pointer
    end type
     
    type multiboot_tag_smbios
      dim as multiboot_uint32_t type
      dim as multiboot_uint32_t size
      dim as multiboot_uint8_t major
      dim as multiboot_uint8_t minor
      dim as multiboot_uint8_t reserved(6)
      dim as multiboot_uint8_t tables(0)
    end type
     
    type multiboot_tag_old_acpi
      dim as multiboot_uint32_t type
      dim as multiboot_uint32_t size
      dim as multiboot_uint8_t rsdp(0)
    end type
     
    type multiboot_tag_new_acpi
      dim as multiboot_uint32_t type
      dim as multiboot_uint32_t size
      dim as multiboot_uint8_t rsdp(0)
    end type
     
    type multiboot_tag_network
      dim as multiboot_uint32_t type
      dim as multiboot_uint32_t size
      dim as multiboot_uint8_t dhcpack(0)
    end type
