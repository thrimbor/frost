namespace pic
    const MASTER_COMMAND as ubyte = &h20
    const MASTER_DATA    as ubyte = &h21
    const SLAVE_COMMAND  as ubyte = &hA0
    const SLAVE_DATA     as ubyte = &hA1
    
    '// the end-of-interrupt command:
    const COMMAND_EOI as ubyte = &h20
    
    declare sub init ()
    declare sub send_eoi (irq as ubyte)
end namespace
