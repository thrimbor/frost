#include "../../kernel/include/syscall_defs.bi"
#include "libfrost_internal.bi"

sub frost_syscall_vfs_create_node (nodeinfo as vfs_create_info ptr)
	syscall_param1(SYSCALL_VFS_CREATE_NODE, nodeinfo)
end sub

'function frost_syscall_vfs_open (path as zstring ptr, flags as uinteger) as uinteger
'    syscall_param2_ret(SYSCALL_VFS_OPEN, function, path, flags)
'end function

sub frost_syscall_vfs_open (openinfo as vfs_open_info ptr)
    syscall_param1(SYSCALL_VFS_OPEN, openinfo)
end sub
