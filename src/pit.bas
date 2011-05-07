#include once "inc/pit.bi"

namespace pit
    sub set_frequency (frequency as ushort)
        out(pit.COMMAND_PORT, &b00110110)
        out(pit.DATA_PORT, lobyte(1193180 / frequency))
        out(pit.DATA_PORT, hibyte(1193180 / frequency))
    end sub
end namespace
