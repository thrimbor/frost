#include once "cpu.bi"

namespace panic
    declare sub set_clear_on_panic (b as ubyte)
    declare sub show (panic_type as uinteger, cpu as cpu_state ptr)
end namespace