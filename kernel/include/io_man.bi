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

#include "process.bi"

declare sub init_ports ()
declare function request_port (process as process_type ptr, port as uinteger) as boolean
declare function release_port (process as process_type ptr, port as uinteger) as boolean
declare function request_port_range (process as process_type ptr, start_port as uinteger, length as uinteger) as boolean
declare function release_port_range (process as process_type ptr, start_port as uinteger, length as uinteger) as boolean
