#include once "cpu.bi"

namespace tasks
    declare sub init_multitasking()
    declare function schedule (cpu as cpu_state ptr) as cpu_state ptr
end namespace