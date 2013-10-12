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

extern kernel_start_label alias "kernel_start_label" as byte
extern kernel_end_label   alias "kernel_end_label"   as byte

#define kernel_start @kernel_start_label
#define kernel_end   @kernel_end_label

#include "gdt.bi"
common shared tss_ptr as task_state_segment ptr

const nullptr as any ptr = cast(any ptr, 0)

type boolean as integer

const true as boolean = -1
const false as boolean = 0

type paddr_t as uinteger
type vaddr_t as uinteger
type addr_t as uinteger
#define caddr(cf) cuint(cf)
