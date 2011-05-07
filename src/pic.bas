#include "inc/pic.bi"

namespace pic
    sub init ()
        '// send ICW1 to both pics
        out(pic.MASTER_COMMAND, &h11)
        out(pic.SLAVE_COMMAND, &h11)
        
        '// ICW2 is where we want to map the interrupts
        '// we map them directly after the exceptions
        out(pic.MASTER_DATA, &h20)
        out(pic.SLAVE_DATA, &h28)
        
        '// ICW3: tell the PICs that they're connected through IRQ 2
        out(pic.MASTER_DATA, &h04)
        out(pic.SLAVE_DATA, &h02)
        
        '// ICW4: tell the PICs we're in 8086-mode
        out(pic.MASTER_DATA, &h01)
        out(pic.SLAVE_DATA, &h01)
    end sub
    
    sub send_eoi (irq as ubyte)
        out(pic.MASTER_COMMAND, pic.COMMAND_EOI)
        if (irq>7) then out(pic.SLAVE_COMMAND, pic.COMMAND_EOI)
    end sub
end namespace
