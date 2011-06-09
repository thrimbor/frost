#include once "inc/tasks.bi"
#include once "inc/pmm.bi"
#include once "inc/cpu.bi"
#include once "inc/paging.bi"
#include once "inc/elf32.bi"
#include once "inc/video.bi"

'// these two symbols are provided by our linkerscript. do not access them directly, they don't have variables behind them!
extern kernel_start alias "kernel_start" as byte
extern kernel_end   alias "kernel_end"   as byte

namespace tasks
    dim shared first_task as task_type ptr = 0
    dim shared current_task as task_type ptr = 0
    
    function generate_pid () as uinteger
        static next_pid as uinteger = 0
        next_pid += 1
        return next_pid-1
    end function
    
    function init_task (entry as any ptr) as task_type ptr
        dim kernelstack as any ptr = pmm.alloc()
        dim userstack as any ptr = pmm.alloc()
        dim task as task_type ptr = pmm.alloc()
        dim cpu as cpu_state ptr = (kernelstack+4096-sizeof(cpu_state))
        
        cpu->eax = 0
        cpu->ebx = 0
        cpu->ecx = 0
        cpu->edx = 0
        cpu->esi = 0
        cpu->edi = 0
        cpu->ebp = 0
        cpu->eip = cuint(entry)
        cpu->esp = cuint(userstack)+4096
        cpu->cs = &h18 or &h03
        cpu->ss = &h20 or &h03
        cpu->eflags = &h200
        
        task->cpu = cpu
        
        '// give the task a pid
        task->pid = generate_pid()
        
        '// now the task needs a page-directory
        task->page_directory = pmm.alloc()
        pmm.memset(cuint(task->page_directory), 0, 4096)
        
        '// map the kernel to every process
        dim kernel_addr as uinteger = cuint(@kernel_start)
        dim kernel_end_addr as uinteger = cuint(@kernel_end)
        while (kernel_addr < kernel_end_addr)
            paging.map_page(task->page_directory, kernel_addr, kernel_addr, (paging.FLAG_PRESENT or paging.FLAG_USERSPACE))
            kernel_addr += 4096
        wend
        
        task->next_entry = first_task
        first_task = task
        
        return task
    end function
    
    function schedule (cpu as cpu_state ptr) as cpu_state ptr
        if (not(current_task = 0)) then current_task->cpu = cpu
        
        if (current_task = 0) then
            current_task = first_task
        else
            current_task = current_task->next_entry
            if (current_task = 0) then current_task = first_task
        end if
        
        return current_task->cpu
    end function
    
    function get_current_task () as task_type ptr
        return current_task
    end function
    
    function check_elf_header (header as elf32.Elf32_Ehdr ptr) as integer
        if (not(header->e_ident.EI_MAGIC = elf32.ELF_MAGIC)) then return 2
        if (not(header->e_type = elf32.ELF_ET_EXEC)) then return 3
        if (not(header->e_machine = elf32.ELF_EM_386)) then return 4
        if (not(header->e_ident.EI_CLASS = elf32.ELF_CLASS_32)) then return 5
        if (not(header->e_ident.EI_DATA = elf32.ELF_DATA_2LSB)) then return 6
        if (not(header->e_version = elf32.ELF_EV_CURRENT)) then return 7
        return -1
    end function
    
    sub init_elf (image as any ptr)
        dim task as task_type ptr
        dim elf_header as elf32.Elf32_Ehdr ptr = image
        if (check_elf_header(elf_header) > 0) then
            video.cout("error in the elf-header",video.endl)
            return
        end if
        
        dim ph_entry as elf32.Elf32_Phdr ptr = cast(any ptr, cuint(image) + elf_header->e_phoff)
        for counter as uinteger = 1 to elf_header->e_phnum
            if (not(ph_entry->p_type = elf32.ELF_PT_LOAD)) then
                ph_entry = cast(any ptr, cuint(ph_entry) + elf_header->e_phentsize)
                continue for
            end if
            pmm.memcpy(ph_entry->p_vaddr, (cuint(image)+ph_entry->p_offset), ph_entry->p_filesz)
        next
        
        task = init_task(cast(any ptr, elf_header->e_entry))
    end sub
    
    sub create_tasks_from_mb (mbinfo as multiboot_info ptr)
        dim mods_ptr as multiboot_mod_list ptr = cast(any ptr, mbinfo->mods_addr)
        init_elf(cast(any ptr, mods_ptr->mod_start))
    end sub
end namespace