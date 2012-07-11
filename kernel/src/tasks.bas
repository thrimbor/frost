#include "tasks.bi"
#include "pmm.bi"
#include "cpu.bi"
#include "vmm.bi"
#include "kmm.bi"
#include "mem.bi"
#include "elf32.bi"
#include "video.bi"
#include "kernel.bi"

namespace tasks
    dim shared first_task as task_type ptr = 0
    dim shared current_task as task_type ptr = 0
    
    function generate_pid () as uinteger
        static next_pid as uinteger = 0
        next_pid += 1
        return next_pid-1
    end function
    
    '' todo:
    ''   - create a vmm context
    ''   - clone the kernel context into it
    ''   - map the tasks data into it
    ''   - create a first thread inside the context
    function task_create (entry_point as any ptr, parent as task_type ptr = 0) as task_type ptr
		dim task as task_type ptr = kmalloc(sizeof(task_type))
		
		'' task is not ready to be run yet
		task->state = STATE_DISABLED
		
		'' set a pid
		task->pid = generate_pid()
		
		'' set the parent task
		if (parent <> 0) then
			task->parent = parent
		end if
		
		'' insert the task into the list
		task->next_entry = first_task
		first_task = task
		
		return task
	end function
	
	function thread_create (task as task_type ptr, entry as any ptr) as thread_type ptr
		dim thread as thread_type ptr = kmalloc(sizeof(thread_type))
		dim cpu as cpu_state ptr
		
		'' set the parent-task
		thread->task = task
		
		'' assign a thread-id
		thread->id = task->next_tid
		task->next_tid += 1
		
		'' thread is currently disabled
		thread->state = STATE_DISABLED
		
		'' put the thread into the list
		thread->next_entry = task->threads
		task->threads = thread
		
		'' set the ticks
		thread->ticks_max = MAX_TICKS
		thread->ticks_left = MAX_TICKS
		
		'' kernel stack needs to be mapped into the kernels adress space
		thread->kernelstack_bottom = vmm.alloc()
		
		'' reserve space for the user stack
		thread->userstack_bottom = pmm.alloc()
		
		'' initialize the threads cpu-state
		cpu = (thread->kernelstack_bottom+pmm.PAGE_SIZE-sizeof(cpu_state))
		
		cpu->eax = 0
		cpu->ebx = 0
		cpu->ecx = 0
		cpu->edx = 0
		cpu->esi = 0
		cpu->edi = 0
		cpu->ebp = 0
		cpu->eip = cuint(entry)
		cpu->esp = cuint(thread->userstack_bottom)+pmm.PAGE_SIZE
		cpu->cs = &h18 or &h03
		cpu->ss = &h20 or &h03
		
		thread->cpu = cpu
		
		thread->state = STATE_RUNNING
		
		return thread
	end function
    
    '' modify scheduler to take care of the task-state
    '' maybe use a for loop to find a runnable task?
    function schedule (cpu as cpu_state ptr) as cpu_state ptr
    #if 0
        if (current_task <> 0) then current_task->cpu = cpu
        
        if (current_task = 0) then
            current_task = first_task
        else
            current_task->ticks_left -= 1
            if (current_task->ticks_left = 0) then
                current_task->ticks_left = current_task->ticks_max
                current_task = current_task->next_entry
                if (current_task = 0) then current_task = first_task
            end if
        end if
        
        return current_task->cpu
    #endif
    end function
    
    function get_current_task () as task_type ptr
        return current_task
    end function
    
    sub init_elf (image as any ptr)
#if 0
        dim task as task_type ptr
        dim task_pd as uinteger ptr
        dim bytes_on_first_page as uinteger
        dim offset_on_first_page as uinteger
        dim cur_page as byte ptr
        dim pages as uiteger
        dim elf_header as elf32.Elf32_Ehdr ptr = image
        if (check_elf_header(elf_header) > 0) then
            video.cout(!"error in the elf-header\n")
            return
        end if
        
        
        dim ph_entry as elf32.Elf32_Phdr ptr = cast(any ptr, cuint(image) + elf_header->e_phoff)
        for counter as uinteger = 1 to elf_header->e_phnum
            if (ph_entry->p_type <> elf32.ELF_PT_LOAD) then
                ph_entry = cast(any ptr, cuint(ph_entry) + elf_header->e_phentsize)
                continue for
            end if
            
            offset_on_first_page = (ph_entry->p_vaddr mod pmm.PAGE_SIZE)
            if (ph_entry->p_filesz > (pmm.PAGE_SIZE - offset_on_first_page)) then
                bytes_on_first_page = pmm.PAGE_SIZE - offset_on_first_page
            else
                bytes_on_first_page = ph_entry->p_filesz
            end if
            
            pages = 1 + ((ph_entry->p_offset + ph_entry->p_memsz) / pmm.PAGE_SIZE) - (ph_entry->p_offset / pmm.PAGE_SIZE)
            
            video.cout("We have to map ")
            video.cout(pages)
            video.cout(!"pages\n")
            
            base = (ph_entry->p_vaddr / pmm.PAGE_SIZE) * pmm.PAGE_SIZE
            
            '' map the pages into the adress-space of the process
            for counter as uinteger = 1 to pages
                cur_page = pmm.alloc()
                vmm.map_page(task_pd, (base + counter * pmm.PAGE_SIZE), cur_page, (vmm.FLAG_PRESENT or vmm.FLAG_WRITE or vmm.FLAG_USERSPACE))
            next
            
            '' copy the stuff
            '' map the first page into the kernel address space and copy the bytes
            '' tyndur code: modules.c:299
            
            
            'pmm.memcpy(ph_entry->p_vaddr, (cuint(image)+ph_entry->p_offset), ph_entry->p_filesz)
        next
        
        task = init_task(cast(any ptr, elf_header->e_entry))
#endif
    end sub
    
    sub create_tasks_from_mb (mbinfo as multiboot_info ptr)
        dim mods_ptr as multiboot_mod_list ptr = cast(any ptr, mbinfo->mods_addr)
        init_elf(cast(any ptr, mods_ptr->mod_start))
    end sub
end namespace
