/'
 ' FROST x86 microkernel
 ' Copyright (C) 2010-2015  Stefan Schmidt
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
#include "kmm.bi"
#include "refcount_smartptr.bi"

const VFS_FLAGS_KERNEL_NODE as integer = &h1

type vfs_node extends RefCounted
	name as zstring ptr

	flags as integer
	permissions as integer

	uid as integer
	gid as integer

	union
		owner as process_type ptr

		mem as any ptr
	end union

	parent as vfs_node ptr
	child_list as list_head
	node_list as list_head

	declare operator new (size as uinteger) as any ptr
	declare operator delete (buffer as any ptr)
	declare constructor (name as zstring ptr, parent as vfs_node ptr, flags as integer)
end type

type vfs_fd
	id as integer
	seekptr as uinteger<64>
	node as vfs_node ptr

	declare operator new (size as uinteger) as any ptr
	declare operator delete (buffer as any ptr)
	declare constructor (process as process_type ptr, node as vfs_node ptr)
end type

common shared vfs_root as vfs_node ptr

declare sub vfs_init ()
declare function vfs_parse_path (path as zstring) as vfs_node ptr
declare function vfs_open (thread as thread_type ptr, path as zstring ptr, flags as uinteger) as vfs_fd ptr
