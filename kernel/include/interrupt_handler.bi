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

#include "isf.bi"

'' the global interrupt-handler
declare function handle_interrupt cdecl (isf as interrupt_stack_frame ptr) as interrupt_stack_frame ptr

'' here are all stubs:
declare sub int_stub_0 ()
declare sub int_stub_1 ()
declare sub int_stub_2 ()
declare sub int_stub_3 ()
declare sub int_stub_4 ()
declare sub int_stub_5 ()
declare sub int_stub_6 ()
declare sub int_stub_7 ()
declare sub int_stub_8 ()
declare sub int_stub_9 ()
declare sub int_stub_10 ()
declare sub int_stub_11 ()
declare sub int_stub_12 ()
declare sub int_stub_13 ()
declare sub int_stub_14 ()
declare sub int_stub_15 ()
declare sub int_stub_16 ()
declare sub int_stub_17 ()
declare sub int_stub_18 ()

'' now the irq's
declare sub int_stub_32 ()
declare sub int_stub_33 ()
declare sub int_stub_34 ()
declare sub int_stub_35 ()
declare sub int_stub_36 ()
declare sub int_stub_37 ()
declare sub int_stub_38 ()
declare sub int_stub_39 ()
declare sub int_stub_40 ()
declare sub int_stub_41 ()
declare sub int_stub_42 ()
declare sub int_stub_43 ()
declare sub int_stub_44 ()
declare sub int_stub_45 ()
declare sub int_stub_46 ()
declare sub int_stub_47 ()

'' and the syscall-interrupt
declare sub int_stub_98 ()
