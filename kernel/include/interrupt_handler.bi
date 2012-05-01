#include once "cpu.bi"

'' the global interrupt-handler
declare function handle_interrupt cdecl (cpu as cpu_state ptr) as cpu_state ptr

'' here are all stubs:
declare sub int_stub_0 ()
declare sub int_stub_1 ()
declare sub int_stub_2 ()
declare sub int_stub_3 ()
declare sub int_stub_4 ()
declare sub int_stub_5 ()
declare sub int_stub_6 ()
declare sub int_stub_7 ()
declare sub int_stub_8 ()
declare sub int_stub_9 ()
declare sub int_stub_10 ()
declare sub int_stub_11 ()
declare sub int_stub_12 ()
declare sub int_stub_13 ()
declare sub int_stub_14 ()
declare sub int_stub_15 ()
declare sub int_stub_16 ()
declare sub int_stub_17 ()
declare sub int_stub_18 ()

'' now the irq's
declare sub int_stub_32 ()
declare sub int_stub_33 ()
declare sub int_stub_34 ()
declare sub int_stub_35 ()
declare sub int_stub_36 ()
declare sub int_stub_37 ()
declare sub int_stub_38 ()
declare sub int_stub_39 ()
declare sub int_stub_40 ()
declare sub int_stub_41 ()
declare sub int_stub_42 ()
declare sub int_stub_43 ()
declare sub int_stub_44 ()
declare sub int_stub_45 ()
declare sub int_stub_46 ()
declare sub int_stub_47 ()

'' and the syscall-interrupt
declare sub int_stub_98 ()
