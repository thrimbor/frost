/'
 ' FROST
 ' Copyright (C) 2010-2017  Stefan Schmidt
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

#include "../libfrost/frost.bi"
'asm
'    .global fb_ctor__init
'end asm

sub vfs_handler (node_id as uinteger)
	frost_syscall_43(strptr("vfs handler called"))
	'' FIXME
	frost_syscall_thread_exit()
    'do : loop
end sub

sub open_callback ()
    frost_syscall_43(strptr("open-callback called"))
    '' FIXME
    frost_syscall_thread_exit()
    'do : loop
end sub

sub main ()
	frost_syscall_43(strptr("this is a test"))

    dim ninfo as vfs_create_info
    ninfo.pathname = strptr("/vfs_2/testnode")
    ninfo.nodename = strptr("INIT_WAS_HERE")
    ninfo.handler = @vfs_handler
    ninfo.id = 0
	frost_syscall_vfs_create_node(@ninfo)

    dim openinfo as vfs_open_info
    openinfo.path = strptr("/vfs_2/testnode/INIT_WAS_HERE")
    openinfo.flags = &hDEADC0DE
    openinfo.handle = &hDEADBEEF
    openinfo.callback = @open_callback
    frost_syscall_vfs_open(@openinfo)

	do
		frost_syscall_thread_yield()
	loop
end sub
