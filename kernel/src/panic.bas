#include "panic.bi"
#include "cpu.bi"
#include "video.bi"

namespace panic
    dim shared clear_on_panic as ubyte = 1
    
    sub set_clear_on_panic (b as ubyte)
        clear_on_panic = b
    end sub
    
    sub show (panic_type as uinteger, cpu as cpu_state ptr)
        video.set_color(0,3)
        
        if (clear_on_panic = 1) then
            video.clean(3)
        end if
        
        select case (panic_type)
            case 1
                video.fout("\n\n")
                'video.set_color(4,0)
                select case (cpu->int_nr)
                    case &h00
                        video.fout("EXCEPTION 0x00 - Divide by Zero (#DE)\n")
                    case &h01
                        video.fout("EXCEPTION 0x01 - Debug (#DB)\n")
                    case &h02
                        video.fout("EXCEPTION 0x02 - Non-maskable Interrupt (#NMI)\n")
                    case &h03
                        video.fout("EXCEPTION 0x03 - Breakpoint (#BP)\n")
                    case &h04
                        video.fout("EXCEPTION 0x04 - Overflow (#OF)\n")
                    case &h05
                        video.fout("EXCEPTION 0x05 - Bound Range Exceeded (#BR)\n")
                    case &h06
                        video.fout("EXCEPTION 0x06 - Invalid Opcode (#UD)\n")
                    case &h07
                        video.fout("EXCEPTION 0x07 - Device Not Available (#NM)\n")
                    case &h08
                        video.fout("EXCEPTION 0x08 - Double Fault (#DF)\n")
                    case &h09
                        video.fout("EXCEPTION 0x09 - Coprocessor Segment Overrun\n")
                    case &h0A
                        video.fout("EXCEPTION 0x0A - Invalid TSS (#TS)\n")
                    case &h0B
                        video.fout("EXCEPTION 0x0B - Segment Not Present (#NP)\n")
                    case &h0C
                        video.fout("EXCEPTION 0x0C - Stack-Segment Fault (#SS)\n")
                    case &h0D
                        video.fout("EXCEPTION 0x0D - General Protection Fault (#GP)\n")
                    case &h0E
                        video.fout("EXCEPTION 0x0E - Page Fault (#PF)\n")
                    case &h0F
                        video.fout("EXCEPTION 0x0F - RESERVED\n")
                    case &h10
                        video.fout("EXCEPTION 0x10 - x87 Floating Point (#MF)\n")
                    case &h11
                        video.fout("EXCEPTION 0x11 - Alignment Check (#AC)\n")
                    case &h12
                        video.fout("EXCEPTION 0x12 - Machine Check (#MC)\n")
                    case &h13
                        video.fout("EXCEPTION 0x13 - SIMD Floating Point (#XM/#XF)\n")
                    case &h14 to &h1F
                        video.fout("EXCEPTION - RESERVED EXCEPTION\n")
                end select
                
                video.fout("\n")
                video.fout("error: 0x%h########I\n", cpu->errorcode)
                
                dim as uinteger t_cr0, t_cr2, t_cr3
                
                asm
                    mov eax, cr0
                    mov [t_cr0], eax
                    mov eax, cr2
                    mov [t_cr2], eax
                    mov eax, cr3
                    mov [t_cr3], eax
                end asm
                video.fout("cr0: 0x%h########I, cr2: 0x%h########I, cr3: 0x%h########I\n", t_cr0, t_cr2, t_cr3)
                video.fout("eax: 0x%h########I, ebx: 0x%h########I, ecx: 0x%h########I, edx: 0x%h########I\n", cpu->eax, cpu->ebx, cpu->ecx, cpu->edx)
                video.fout("ebp: 0x%h########I, esp: 0x%h########I, esi: 0x%h########I, edi: 0x%h########I\n", cpu->ebp, cpu->esp, cpu->esi, cpu->edi)
                video.fout("eflags: 0x%h########I\n", cpu->eflags)
                
                ' print some other registers here
        end select
        
        video.fout("\nSYSTEM HALTED")
        asm cli
        asm hlt
    end sub
end namespace
