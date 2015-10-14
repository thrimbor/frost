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
 
#include "vfs.bi"
#include "kernel.bi"
#include "string_tokenizer.bi"
#include "zstring.bi"
#include "video.bi"

'' FIXME: We absolutely NEED refcounted pointers for the nodes! Otherwise we'll get serious memory corruption!


sub vfs_init ()
	vfs_root = new vfs_node("vfs_root", nullptr, VFS_FLAGS_KERNEL_NODE)
	
	var one = new vfs_node("vfs_1", vfs_root, VFS_FLAGS_KERNEL_NODE)
	var two = new vfs_node("vfs_2", vfs_root, VFS_FLAGS_KERNEL_NODE)
	var three = new vfs_node("vfs_3", vfs_root, VFS_FLAGS_KERNEL_NODE)
	
	var testnode = new vfs_node("testnode", two, VFS_FLAGS_KERNEL_NODE)
	
	var t = vfs_parse_path("/vfs_2/testnode")
	video_fout(!"node name: %z\n", t->name)
end sub

operator vfs_node.new (size as uinteger) as any ptr
	return kmalloc(size)
end operator

operator vfs_node.delete (buffer as any ptr)
	kfree(buffer)
end operator

constructor vfs_node (name as zstring ptr, parent as vfs_node ptr, flags as integer)
	'' TODO: don't rely on userspace string pointers, copy instead
	this.name = name
	this.parent = parent
	this.flags = flags
	
	if (parent <> nullptr) then
		'' TODO: maybe keep the list sorted somehow?
		parent->child_list.insert_after(@this.node_list)
	end if
end constructor

operator vfs_fd.new (size as uinteger) as any ptr
	return kmalloc(size)
end operator

operator vfs_fd.delete (buffer as any ptr)
	kfree(buffer)
end operator

constructor vfs_fd (process as process_type ptr, node as vfs_node ptr)
	'' TODO: - generate an id
	''		 - add ourself to a list of descriptors for this process
end constructor

function vfs_parse_path (path as zstring) as vfs_node ptr
	'' TODO: what's with relative paths?
	'' TODO: can we break up that function into multiple smaller ones? (e.g. findChildByName)
	
	if (path[0] = asc("/")) then
		dim cur_node as vfs_node ptr = vfs_root
		dim st as StringTokenizer = StringTokenizer(@path)
		do
			dim x as zstring ptr = st.getToken(strptr("/"))
			if (x = 0) then exit do
			
			dim old_node as vfs_node ptr = cur_node
			'' loop through all child nodes, search for the one with the right name
			list_foreach (child, cur_node->child_list)
				dim child_node as vfs_node ptr = LIST_GET_ENTRY(child, vfs_node, node_list)
				
				if (zstring_cmp(*x, *child_node->name) = 0) then
					cur_node = child_node
					list_foreach_exit
				end if
			list_next (child)
			
			'' no fitting child found
			if (old_node = cur_node) then return nullptr
		loop
		
		return cur_node
	end if
end function

function vfs_open (thread as thread_type ptr, path as zstring ptr, flags as uinteger) as vfs_fd ptr
	'' TODO: what about permissions?
	
	'' parse the path and get the node
	dim node as vfs_node ptr = vfs_parse_path(*path)
	if (node = nullptr) then return nullptr
	
	'' create a new file-descriptor
	dim fd as vfs_fd ptr = new vfs_fd(thread->parent_process, node)
end function
