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

#include "kernel.bi"
#include "isf.bi"
#include "video.bi"
#include "cpu.bi"

common shared panic_clear_on_panic as boolean
declare sub panic_set_clear_on_panic (b as boolean)
declare sub panic_exception (isf as interrupt_stack_frame ptr)
declare sub panic_hlt ()

#macro panic_error (msg, params...)
	cpu_disable_interrupts()
	if (panic_clear_on_panic) then video_clean()
	printk(LOG_ERR COLOR_RED !"\n--------------------------------------------------------------------------------")
	printk(LOG_ERR !"\nKERNEL PANIC\n")
	printk(LOG_ERR !"file: %s, function: %s, line: %u\n\n", @__FILE__, @__FUNCTION__, cuint(__LINE__))
	printk(LOG_ERR !"reason: ")
	printk(LOG_ERR msg, params)

	panic_hlt()
#endmacro
