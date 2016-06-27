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
 
#include "vfs.bi"
#include "kernel.bi"
#include "string_tokenizer.bi"
#include "zstring.bi"
#include "video.bi"

DEFINE_LIST(vfs_node)
DEFINE_REFCOUNTPTR(vfs_node)

dim shared vfs_root as RefCountPtr(vfs_node)

sub vfs_init ()
	vfs_root = new vfs_node("vfs_root", nullptr, VFS_FLAGS_KERNEL_NODE)
	
	var one = new vfs_node("vfs_1", vfs_root.ref, VFS_FLAGS_KERNEL_NODE)
	var two = new vfs_node("vfs_2", vfs_root.ref, VFS_FLAGS_KERNEL_NODE)
	var three = new vfs_node("vfs_3", vfs_root.ref, VFS_FLAGS_KERNEL_NODE)
	
	var testnode = new vfs_node("testnode", two, VFS_FLAGS_KERNEL_NODE)
	
	var t = vfs_parse_path("/vfs_2/testnode")
	printk(LOG_DEBUG !"node name: %s\n", t->name)
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

function vfs_node.getChildByName (name as zstring) as RefCountPtr(vfs_node)
	'' loop through all child nodes, search for the one with the right name
	list_foreach(child, this.child_list)
		dim child_node as RefCountPtr(vfs_node) = child->get_owner()
		
		if (zstring_cmp(name, *child_node->name) = 0) then
			return child_node
		end if
	list_next(child)
	
	return nullptr
end function

operator vfs_fd.new (size as uinteger) as any ptr
	return kmalloc(size)
end operator

operator vfs_fd.delete (buffer as any ptr)
	kfree(buffer)
end operator

constructor vfs_fd (process as process_type ptr, node as RefCountPtr(vfs_node))
	'' TODO: - generate an id
	''		 - add ourself to a list of descriptors for this process
end constructor

function vfs_parse_path (path as zstring) as RefCountPtr(vfs_node)
	'' TODO: what's with relative paths?
	
	if (path[0] = asc("/")) then
		dim cur_node as RefCountPtr(vfs_node) = vfs_root
		dim st as StringTokenizer = StringTokenizer(@path)
		do
			dim x as zstring ptr = st.getToken(strptr("/"))
			if (x = 0) then exit do
			
			cur_node = cur_node->getChildByName(*x)
			
			if (cur_node.ref = nullptr) then exit do
		loop
		
		return cur_node
	end if
end function

function vfs_open (thread as thread_type ptr, path as zstring ptr, flags as uinteger) as vfs_fd ptr
	'' TODO: what about permissions?
	
	'' parse the path and get the node
	dim node as RefCountPtr(vfs_node) = vfs_parse_path(*path)
	if (node.get_count()) then return nullptr
	
	'' create a new file-descriptor
	dim fd as vfs_fd ptr = new vfs_fd(thread->parent_process, node)
end function
