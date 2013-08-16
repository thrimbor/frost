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

#pragma once

namespace pic
    const MASTER_COMMAND as ubyte = &h20
    const MASTER_DATA    as ubyte = &h21
    const SLAVE_COMMAND  as ubyte = &hA0
    const SLAVE_DATA     as ubyte = &hA1
    
    '' the end-of-interrupt command:
    const COMMAND_EOI as ubyte = &h20
    
    declare sub init ()
    declare sub send_eoi (irq as ubyte)
end namespace
