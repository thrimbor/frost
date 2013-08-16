/'
 ' FROST x86 microkernel
 ' Copyright (C) 2010-2013  Stefan Schmidt
 ' 
 ' This program is free software: you can redistribute it and/or modify
 ' it under the terms of the GNU General Public License as published by
 ' the Free Software Foundation, either version 3 of the License, or
 ' (at your option) any later version.
 ' 
 ' This program is distributed in the hope that it will be useful,
 ' but WITHOUT ANY WARRANTY; without even the implied warranty of
 ' MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 ' GNU General Public License for more details.
 ' 
 ' You should have received a copy of the GNU General Public License
 ' along with this program.  If not, see <http://www.gnu.org/licenses/>.
 '/

#include "pic.bi"

namespace pic
    sub init ()
        '' send ICW1 to both pics
        out(pic.MASTER_COMMAND, &h11)
        out(pic.SLAVE_COMMAND, &h11)
        
        '' ICW2 is where we want to map the interrupts
        '' we map them directly after the exceptions
        out(pic.MASTER_DATA, &h20)
        out(pic.SLAVE_DATA, &h28)
        
        '' ICW3: tell the PICs that they're connected through IRQ 2
        out(pic.MASTER_DATA, &h04)
        out(pic.SLAVE_DATA, &h02)
        
        '' ICW4: tell the PICs we're in 8086-mode
        out(pic.MASTER_DATA, &h01)
        out(pic.SLAVE_DATA, &h01)
    end sub
    
    sub send_eoi (irq as ubyte)
        out(pic.MASTER_COMMAND, pic.COMMAND_EOI)                '' send the EOI-command to the first PIC
        if (irq>7) then out(pic.SLAVE_COMMAND, pic.COMMAND_EOI) '' if the irq was above 7, the second PIC needs to be informed also
    end sub
end namespace
