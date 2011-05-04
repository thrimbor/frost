/* This is the linkerscript for the frost-kernel */
/* It's only a rough draft, so it may contain errors */
ENTRY(_start)

SECTIONS
{
	/*
	 * This is where we want to have the kernel loaded
	 *
	 */
	. = 0x100000;
	
	/*
	 * The multiboot-header has to be in the first 8 KB,
	 * so we just put it at the beginning
	 */
	.text : {
		*(multiboot)
		*(.text)
	}
	.data ALIGN(4096) : {
		*(.data)
	}
	.rodata ALIGN(4096) : {
		*(.rodata)
	}
	.bss ALIGN(4096) : {
		*(.bss)
	}
}
