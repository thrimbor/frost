/* This is the linkerscript for the frost-kernel */
ENTRY(_start)

SECTIONS
{
    /*
	 * This is where we want to have the kernel loaded
	 *
	 */
	. = 0x100000;
	kernel_start_label = .;

	/*
	 * The multiboot-header has to be in the first 8 KB,
	 * so we just put it at the beginning
	 */
	.text : {
		*(multiboot)
		*(.text)
	}
	.data ALIGN(4096) : {
		start_ctors = .;
		*(.ctor*)
		end_ctors = .;
		start_dtors = .;
		*(.dtor*)
		end_dtors = .;

		*(.data)
	}
	.rodata ALIGN(4096) : {
		*(.rodata)
	}
	.bss ALIGN(4096) : {
		*(.bss)
	}

	.= ALIGN(4096);
	kernel_end_label = .;
}
