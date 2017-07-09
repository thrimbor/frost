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

#include "kernel.bi"
#include "syscall.bi"
#include "process.bi"
#include "video.bi"
#include "io_man.bi"
#include "panic.bi"
#include "interrupt_handler.bi"
#include "interrupt.bi"
#include "vfs.bi"


function syscall_handler (funcNumber as uinteger, param1 as uinteger, param2 as uinteger, param3 as uinteger) as uinteger
	dim cur_thread as thread_type ptr = get_current_thread()

	select case (funcNumber)
		case SYSCALL_PROCESS_GET_PID
			return cur_thread->parent_process->id

		case SYSCALL_PROCESS_GET_PARENT_PID
			if (cur_thread->parent_process->parent <> nullptr) then
				return cur_thread->parent_process->parent->id
			else
				return 0
			end if

		case SYSCALL_PROCESS_CREATE
			'' TODO: implement

		case SYSCALL_PROCESS_EXIT
			'' TODO: implement

		case SYSCALL_PROCESS_KILL
			'' TODO: implement

		case SYSCALL_THREAD_GET_TID
			return cur_thread->id

		case SYSCALL_THREAD_CREATE
			'' param1 = entrypoint for the thread
			'' param2 = usermode stack size for the thread in pages
			'' FIXME: don't hardcode these values!
			if ((param1 < &h40000000)) then return false

			dim thread as thread_type ptr = new thread_type(cur_thread->parent_process, cast(any ptr, param1), param2)
			if (thread <> nullptr) then
				thread->activate()
				return true
			else
				return false
			end if

		case SYSCALL_THREAD_SLEEP
			'' TODO: implement

		case SYSCALL_THREAD_YIELD
			cur_thread->flags or= THREAD_FLAG_RESCHEDULE

		case SYSCALL_THREAD_EXIT
            'if ((cur_thread->flags and (THREAD_FLAG_POPUP or THREAD_FLAG_TRIGGERS_CALLBACK)) > 0) then
            if (cur_thread->flags and THREAD_FLAG_POPUP) then
            if (cur_thread->flags and THREAD_FLAG_TRIGGERS_CALLBACK) then
                '' this popup-thread triggers a callback, so create the new thread
                '' FIXME: we don't pass the handle back yet
                printk(LOG_ERR !"entry:0x%08X\n", cur_thread->callback_info.callback)
                dim thread as thread_type ptr = new thread_type(cur_thread->callback_info.process, cur_thread->callback_info.callback, 1, THREAD_FLAG_POPUP)
                'printk(LOG_ERR !"thread: 0x%08X\n", thread)
                'printk(LOG_ERR !"kernelstack_bottom: 0x%08X\n", thread->kernelstack_bottom)
                thread->activate()
            end if
            end if

			cur_thread->destroy()

		case SYSCALL_MEMORY_ALLOCATE_PHYSICAL:
			'' bytes, addr, flags
			'' FIXME: not entirely correct, remember page alignment!
			''       - also, don't just allow userspace to map everything!
			'asm hlt
			return cuint(vmm_automap(@cur_thread->parent_process->context, cast(any ptr, param2), param1, &h40000000, &hFFFFFFFF, VMM_FLAGS.USER_DATA))

		case SYSCALL_PORT_REQUEST
			if (request_port(cur_thread->parent_process, param1)) then
				set_io_bitmap()
				return true
			end if

			return false

		case SYSCALL_PORT_RELEASE
			if (release_port(cur_thread->parent_process, param1)) then
				set_io_bitmap()
				return true
			end if

			return false

		case SYSCALL_IRQ_HANDLER_REGISTER
			return register_irq_handler(cur_thread->parent_process, param1, cast(any ptr, param2))

		case SYSCALL_IRQ_HANDLER_EXIT
            '' FIXME: check if the process is actually allowed to do that
            '' FIXME: hardcoding the x86 IRQ-offset here is not a good idea
            interrupt_unmask(param1 + &h20)
			cur_thread->destroy()

		case SYSCALL_IPC_HANDLER_CALL
			'' TODO: implement
			'' param1 = target pid


		case SYSCALL_IPC_HANDLER_SET
			cur_thread->parent_process->ipc_handler = cast(any ptr, param1)

		case SYSCALL_IPC_HANDLER_EXIT
			'' IPC popup threads need to be cleaned up with this syscall
			'' FIXME: what if this wasn't an IPC-thread?
			cur_thread->destroy()

		case SYSCALL_VFS_CREATE_NODE
			'' param1: path-string
			'' param2: name-string
            '' param3: handler-function
			'var pathnode = vfs_parse_path(*cast(zstring ptr, param1))
			'var newnode = new vfs_node(cast(zstring ptr, param2), pathnode.ref, 0)

			'dim as RefCountPtr(vfs_node) tnode = vfs_parse_path("/vfs_2/testnode/INIT_WAS_HERE")
			'printk(LOG_DEBUG !"node name: %s\n", tnode.ref->name)
            dim info as vfs_create_info ptr = cast(vfs_create_info ptr, param1)

            '' create the node, registering the current process as the owner
			var node = vfs_create(info->pathname, info->nodename, cur_thread->parent_process)
            node.ref->handler = info->handler
            assert(info->handler >= &h40000000)
            node.ref->node_uid = info->id

		case SYSCALL_VFS_OPEN
			'' param1: path-string
			'' param2: flags
			'' result: filedescriptor
			'' FIXME: check path-string pointer
			''dim fd as vfs_fd ptr = vfs_open(cur_thread, cast(zstring ptr, param1), param2)
			''return fd->id

            dim openinfo as vfs_open_info ptr = cast(vfs_open_info ptr, param1)

            '' we need to:
            '' - parse the path as far as possible (save the rest!)
            '' - find the process responsible
            '' - create a popup-thread with the rest of the path
            dim node as RefCountPtr(vfs_node) = vfs_parse_path_afap(*openinfo->path)
            if (node.ref = nullptr) then
                '' something went wrong here
            end if

            dim owning_process as process_type ptr = node.ref->owner
            dim thread as thread_type ptr = new thread_type(owning_process, node.ref->handler, 1, THREAD_FLAG_POPUP or THREAD_FLAG_TRIGGERS_CALLBACK)
            '' FIXME: could we place the string data on the stack?
            thread->callback_info.process = cur_thread->parent_process
            thread->callback_info.handle = openinfo->handle
            thread->callback_info.callback = openinfo->callback
            assert(openinfo->callback >= &h40000000)

            printk(LOG_ERR !"thread: 0x%08X\n", thread)
            printk(LOG_ERR !"kernelstack_bottom: 0x%08X\n", thread->kernelstack_bottom)
            printk(LOG_ERR !"stack area: 0x%08X\n", thread->stack_area->address)

            thread->activate()

            '' FIXME: we should somehow mark the popup-thread to indicate it has to call a callback
            ''        we also need to store the callback info in the thread somehow



		case SYSCALL_VFS_CLOSE
			'' param1: filedescriptor
			'' resuslt: errorcode

		case SYSCALL_VFS_READ

		case SYSCALL_VFS_WRITE

		case SYSCALL_FORTY_TWO
			printk(LOG_INFO !"The answer to life, the universe and everything is... 42\n")

		case 43
			printk(LOG_INFO !"%s", param1)

		case else:
			panic_error("Undefined syscall called!")
	end select
end function
