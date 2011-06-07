#include once "inc/panic.bi"
#include once "inc/cpu.bi"
#include once "inc/video.bi"

namespace panic
    sub show (panic_type as uinteger, cpu as cpu_state ptr)
        select case (panic_type)
            case 1
                video.cout("",video.endl)
                video.cout("",video.endl)
                video.set_color(4,0)
                select case (cpu->int_nr)
                    case &h00
                        video.cout("EXCEPTION 0x00 - Divide by Zero (#DE)",video.endl)
                    case &h01
                        video.cout("EXCEPTION 0x01 - Debug (#DB)",video.endl)
                    case &h02
                        video.cout("EXCEPTION 0x02 - Non-maskable Interrupt (#NMI)",video.endl)
                    case &h03
                        video.cout("EXCEPTION 0x03 - Breakpoint (#BP)",video.endl)
                    case &h04
                        video.cout("EXCEPTION 0x04 - Overflow (#OF)",video.endl)
                    case &h05
                        video.cout("EXCEPTION 0x05 - Bound Range Exceeded (#BR)",video.endl)
                    case &h06
                        video.cout("EXCEPTION 0x06 - Invalid Opcode (#UD)",video.endl)
                    case &h07
                        video.cout("EXCEPTION 0x07 - Device Not Available (#NM)",video.endl)
                    case &h08
                        video.cout("EXCEPTION 0x08 - Double Fault (#DF)",video.endl)
                    case &h09
                        video.cout("EXCEPTION 0x09 - Coprocessor Segment Overrun",video.endl)
                    case &h0A
                        video.cout("EXCEPTION 0x0A - Invalid TSS (#TS)",video.endl)
                    case &h0B
                        video.cout("EXCEPTION 0x0B - Segment Not Present (#NP)",video.endl)
                    case &h0C
                        video.cout("EXCEPTION 0x0C - Stack-Segment Fault (#SS)",video.endl)
                    case &h0D
                        video.cout("EXCEPTION 0x0D - General Protection Fault (#GP)",video.endl)
                    case &h0E
                        video.cout("EXCEPTION 0x0E - Page Fault (#PF)",video.endl)
                    case &h0F
                        video.cout("EXCEPTION 0x0F - RESERVED",video.endl)
                    case &h10
                        video.cout("EXCEPTION 0x00 - x87 Floating-Point Exception (#MF)",video.endl)
                    case &h11
                        video.cout("EXCEPTION 0x00 - Alignment Check (#AC)",video.endl)
                    case &h12
                        video.cout("EXCEPTION 0x00 - Machine Check (#MC)",video.endl)
                    case &h13
                        video.cout("EXCEPTION 0x00 - SIMD Floating-Point Exception (#XM/#XF)",video.endl)
                    case &h14 to &h1F
                        video.cout("EXCEPTION - RESERVED EXCEPTION", video.endl)
                end select
                
                dim tmp_register as uinteger
                
                video.cout("",video.endl)
                video.cout("error: ")
                video.cout(cpu->errorcode,video.endl)
                
                asm mov eax, cr0
                asm mov [tmp_register], eax
                video.cout("cr0: ")
                video.cout(tmp_register)
                
                asm mov eax, cr2
                asm mov [tmp_register], eax
                video.cout("    cr2: ")
                video.cout(tmp_register)
                
                asm mov eax, cr3
                asm mov [tmp_register], eax
                video.cout("    cr3: ")
                video.cout(tmp_register,video.endl)
                
                ' print some other registers here
        end select
        
        video.cout("",video.endl)
        video.cout("SYSTEM HALTED")
        asm cli
        asm hlt
    end sub
end namespace