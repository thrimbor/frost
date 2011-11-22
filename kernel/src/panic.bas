#include once "panic.bi"
#include once "cpu.bi"
#include once "video.bi"

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
                video.cout(!"\n\n")
                'video.set_color(4,0)
                select case (cpu->int_nr)
                    case &h00
                        video.cout(!"EXCEPTION 0x00 - Divide by Zero (#DE)\n")
                    case &h01
                        video.cout(!"EXCEPTION 0x01 - Debug (#DB)\n")
                    case &h02
                        video.cout(!"EXCEPTION 0x02 - Non-maskable Interrupt (#NMI)\n")
                    case &h03
                        video.cout(!"EXCEPTION 0x03 - Breakpoint (#BP)\n")
                    case &h04
                        video.cout(!"EXCEPTION 0x04 - Overflow (#OF)\n")
                    case &h05
                        video.cout(!"EXCEPTION 0x05 - Bound Range Exceeded (#BR)\n")
                    case &h06
                        video.cout(!"EXCEPTION 0x06 - Invalid Opcode (#UD)\n")
                    case &h07
                        video.cout(!"EXCEPTION 0x07 - Device Not Available (#NM)\n")
                    case &h08
                        video.cout(!"EXCEPTION 0x08 - Double Fault (#DF)\n")
                    case &h09
                        video.cout(!"EXCEPTION 0x09 - Coprocessor Segment Overrun\n")
                    case &h0A
                        video.cout(!"EXCEPTION 0x0A - Invalid TSS (#TS)\n")
                    case &h0B
                        video.cout(!"EXCEPTION 0x0B - Segment Not Present (#NP)\n")
                    case &h0C
                        video.cout(!"EXCEPTION 0x0C - Stack-Segment Fault (#SS)\n")
                    case &h0D
                        video.cout(!"EXCEPTION 0x0D - General Protection Fault (#GP)\n")
                    case &h0E
                        video.cout(!"EXCEPTION 0x0E - Page Fault (#PF)\n")
                    case &h0F
                        video.cout(!"EXCEPTION 0x0F - RESERVED\n")
                    case &h10
                        video.cout(!"EXCEPTION 0x10 - x87 Floating Point (#MF)\n")
                    case &h11
                        video.cout(!"EXCEPTION 0x11 - Alignment Check (#AC)\n")
                    case &h12
                        video.cout(!"EXCEPTION 0x12 - Machine Check (#MC)\n")
                    case &h13
                        video.cout(!"EXCEPTION 0x13 - SIMD Floating Point (#XM/#XF)\n")
                    case &h14 to &h1F
                        video.cout(!"EXCEPTION - RESERVED EXCEPTION\n")
                end select
                
                dim tmp_register as uinteger
                
                video.cout(!"\nerror: ")
                video.cout(cpu->errorcode,16)
                video.cout(!"\n")
                
                asm mov eax, cr0
                asm mov [tmp_register], eax
                video.cout("cr0: 0x")
                video.cout(tmp_register,16,8)
                
                asm mov eax, cr2
                asm mov [tmp_register], eax
                video.cout(", cr2: 0x")
                video.cout(tmp_register,16,8)
                
                asm mov eax, cr3
                asm mov [tmp_register], eax
                video.cout(", cr3: 0x")
                video.cout(tmp_register,16,8)
                video.cout(!"\n")
                
                
                video.cout("eax: 0x")
                video.cout(cpu->eax,16,8)
                video.cout(", ebx: 0x")
                video.cout(cpu->ebx,16,8)
                video.cout(", ecx: 0x")
                video.cout(cpu->ecx,16,8)
                video.cout(", edx: 0x")
                video.cout(cpu->edx,16,8)
                video.cout(!"\n")
                
                video.cout("ebp: 0x")
                video.cout(cpu->ebp,16,8)
                video.cout(", esp: 0x")
                video.cout(cpu->esp,16,8)
                video.cout(", esi: 0x")
                video.cout(cpu->esi,16,8)
                video.cout(", edi: 0x")
                video.cout(cpu->edi,16,8)
                video.cout(!"\n")
                
                video.cout("eflags: 0x")
                video.cout(cpu->eflags,16,8)
                video.cout(!"\n")
                
                ' print some other registers here
        end select
        
        video.cout(!"\nSYSTEM HALTED")
        asm cli
        asm hlt
    end sub
end namespace