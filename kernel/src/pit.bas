#include "pit.bi"

namespace pit
    sub set_frequency (frequency as ushort)
        out(pit.COMMAND_PORT, &h34)
        out(pit.DATA_PORT, lobyte(1193182 / frequency))
        out(pit.DATA_PORT, hibyte(1193182 / frequency))
    end sub
end namespace
