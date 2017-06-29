/'
 ' FROST x86 microkernel
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

#include "vfs.bi"
#include "kernel.bi"
#include "string_tokenizer.bi"
#include "zstring.bi"
#include "video.bi"
#include "process.bi"

DEFINE_LIST(vfs_node)
DEFINE_REFCOUNTPTR(vfs_node)

dim shared vfs_root as RefCountPtr(vfs_node)
dim shared fd_id_generator as uid128_generator

sub vfs_init ()
	vfs_root = new vfs_node("vfs_root", nullptr, VFS_FLAGS_KERNEL_NODE)

	var one = new vfs_node("vfs_1", vfs_root.ref, VFS_FLAGS_KERNEL_NODE)
	var two = new vfs_node("vfs_2", vfs_root.ref, VFS_FLAGS_KERNEL_NODE)
	var three = new vfs_node("vfs_3", vfs_root.ref, VFS_FLAGS_KERNEL_NODE)

	var testnode = new vfs_node("testnode", two, VFS_FLAGS_KERNEL_NODE)

	var t = vfs_parse_path("/vfs_2/testnode")
	printk(LOG_DEBUG !"node name: %s\n", t->name)
end sub

function vfs_get_root as RefCountPtr(vfs_node)
	return vfs_root
end function

operator vfs_node.new (size as uinteger) as any ptr
	return kmalloc(size)
end operator

operator vfs_node.delete (buffer as any ptr)
	kfree(buffer)
end operator

constructor vfs_node (name as zstring ptr, parent as vfs_node ptr, flags as integer, owner as process_type ptr = nullptr)
	'' TODO: don't rely on userspace string pointers, copy instead
	this.name = name
	this.parent = parent
	this.flags = flags
    this.owner = owner

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

DEFINE_LIST(vfs_fd)

operator vfs_fd.new (size as uinteger) as any ptr
	return kmalloc(size)
end operator

operator vfs_fd.delete (buffer as any ptr)
	kfree(buffer)
end operator

constructor vfs_fd (process as process_type ptr, node as RefCountPtr(vfs_node))
	this.id = fd_id_generator.generate()
	this.node = node

	'' add ourself to a list of descriptors for this process
	process->file_descriptors.insert_after(@this.fd_list)
end constructor

function vfs_parse_path (path as zstring) as RefCountPtr(vfs_node)
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

    return RefCountPtr(vfs_node)
end function

function vfs_parse_path_afap (path as zstring) as RefCountPtr(vfs_node)
	if (path[0] = asc("/")) then
		dim cur_node as RefCountPtr(vfs_node) = vfs_root
		dim st as StringTokenizer = StringTokenizer(@path)
		do
			dim x as zstring ptr = st.getToken(strptr("/"))
			if (x = 0) then exit do

            dim next_node as RefCountPtr(vfs_node) = cur_node->getChildByName(*x)
            if (next_node.ref = nullptr) then exit do
			cur_node = next_node
		loop

		return cur_node
	end if

    return RefCountPtr(vfs_node)
end function

function vfs_create (path as zstring ptr, name_ as zstring ptr, owner as process_type ptr) as RefCountPtr(vfs_node)
	'' the path must be cached in the VFS - we don't support arbitrary paths at the moment (should we ever?)

	'' parse the path to get the parent-node
	dim parent_node as RefCountPtr(vfs_node) = vfs_parse_path(*path)
	if (parent_node.get_count() = 0) then return nullptr

    '' create, register & return the new node
	dim new_node as RefCountPtr(vfs_node) = new vfs_node(name_, parent_node.ref, 0, owner)
    return new_node
end function

function vfs_open (thread as thread_type ptr, path as zstring ptr, flags as uinteger) as vfs_fd ptr
	'' TODO: what about permissions?
    '' TODO: error-signaling is very unprecise

	'' parse the path and get the node
	dim node as RefCountPtr(vfs_node) = vfs_parse_path(*path)
	if (node.get_count() = 0) then return nullptr

	'' create a new file-descriptor
	dim fd as vfs_fd ptr = new vfs_fd(thread->parent_process, node)
    return fd
end function
