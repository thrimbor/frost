/'
 ' FROST x86 microkernel
 ' Copyright (C) 2010-2016  Stefan Schmidt
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
#include "kernel.bi"

declare sub cpu_get_vendor (zstr as zstring ptr)
declare function cpu_has_local_apic () as boolean
declare function cpu_supports_PGE () as boolean
declare function read_msr (msr as uinteger) as ulongint
declare sub write_msr (msr as uinteger, value as ulongint)
declare sub cpu_halt ()
declare sub cpu_disable_interrupts ()
