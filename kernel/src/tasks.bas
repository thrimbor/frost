#include once "tasks.bi"
#include once "pmm.bi"
#include once "cpu.bi"
#include once "vmm.bi"
#include once "kmm.bi"
#include once "mem.bi"
#include once "elf32.bi"
#include once "video.bi"
#include once "kernel.bi"

namespace tasks
    dim shared first_task as task_type ptr = 0
    dim shared current_task as task_type ptr = 0
    
    function generate_pid () as uinteger
        static next_pid as uinteger = 0
        next_pid += 1
        return next_pid-1
    end function
    
    function thread_create (entry as any ptr, process as task_type ptr) as thread_type ptr
        dim thread as thread_type ptr = pmm.alloc()
        dim cpu as cpu_state ptr
        
        '' prepare the memory
        memset(thread, 0, sizeof(thread_type))
        
        '' allocate stacks
        thread->stack_kernel_bottom = pmm.alloc()
        thread->stack_user_bottom = pmm.alloc()
        
        '' set the thread to disabled
        thread->state = STATE_DISABLED
        
        '' assign a thread-id to the task
        thread->tid = process->last_tid
        process->last_tid += 1
        
        '' put the thread into the list
        thread->next_entry = process->threads
        process->threads = thread
        
        '' give the thread some ticks
        thread->ticks_max = MAX_TICKS
        thread->ticks_left = MAX_TICKS
        
        '' initialize the cpu-state
        cpu = (thread->stack_kernel_bottom+pmm.PAGE_SIZE-sizeof(cpu_state))
        
        cpu->eax = 0
        cpu->ebx = 0
        cpu->ecx = 0
        cpu->edx = 0
        cpu->esi = 0
        cpu->edi = 0
        cpu->ebp = 0
        cpu->eip = cuint(entry)
        cpu->esp = cuint(thread->stack_user_bottom)+pmm.PAGE_SIZE
        cpu->cs = &h18 or &h03
        cpu->ss = &h20 or &h03
        cpu->eflags = &h200
        
        thread->cpu = cpu
        
        '' the thread is now ready to be run
        thread->state = STATE_RUNNING
        
        return thread
    end function
    
    function task_create (entry as any ptr, parent as task_type ptr) as task_type ptr
        dim task as task_type ptr = pmm.alloc()
        
        '' set the task to disabled
        task->state = STATE_DISABLED
        
        '' assign a process-id to the task
        task->pid = generate_pid()
        
        '' set the parent
        if (parent <> 0) then
            task->parent = parent
        end if
        
        '' put the task into the list
        task->next_entry = first_task
        first_task = task
    end function
    
    #if 0
    function init_task (entry as any ptr) as task_type ptr
        dim kernelstack as any ptr = pmm.alloc()
        dim userstack as any ptr = pmm.alloc()
        dim task as task_type ptr = pmm.alloc()
        dim cpu as cpu_state ptr = (kernelstack+pmm.PAGE_SIZE-sizeof(cpu_state))
        
        cpu->eax = 0
        cpu->ebx = 0
        cpu->ecx = 0
        cpu->edx = 0
        cpu->esi = 0
        cpu->edi = 0
        cpu->ebp = 0
        cpu->eip = cuint(entry)
        cpu->esp = cuint(userstack)+pmm.PAGE_SIZE
        cpu->cs = &h18 or &h03
        cpu->ss = &h20 or &h03
        cpu->eflags = &h200
        
        task->cpu = cpu
        
        '' give the task a pid
        task->pid = generate_pid()
        
        '' now the task needs a page-directory
        task->page_directory = vmm.create_context()
        
        '' map the kernel to every process
        dim kernel_addr as uinteger = cuint(kernel_start)
        dim kernel_end_addr as uinteger = cuint(kernel_end)
        while (kernel_addr < kernel_end_addr)
            vmm.map_page(task->page_directory, kernel_addr, kernel_addr, (vmm.FLAG_PRESENT or vmm.FLAG_USERSPACE))
            kernel_addr += pmm.PAGE_SIZE
        wend
        
        '' give the process some ticks
        task->ticks_max = MAX_TICKS
        task->ticks_left = MAX_TICKS
        
        task->next_entry = first_task
        first_task = task
        
        return task
    end function
    #endif
    
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
