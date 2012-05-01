
extern kernel_start_label alias "kernel_start_label" as byte
extern kernel_end_label   alias "kernel_end_label"   as byte

#define kernel_start @kernel_start_label
#define kernel_end   @kernel_end_label

common shared tss_ptr as uinteger ptr

const true = 1
const false = 0

type paddr_t as uinteger
type vaddr_t as uinteger
type addr_t as uinteger
#define caddr(cf) cuint(cf)
