FROST
======

#### What is FROST? ####
FROST is a 32-bit operating system based on a microkernel. It is written
entirely in FreeBASIC and Assembly.

#### Dependencies ####
- fbc, tested with 0.90.1 (the FreeBASIC compiler, available on freebasic.net)
- nasm, tested with 2.10.09 (the Netwide Assembler, available on nasm.us)
- GNU make, GNU assembler and the GNU linker

#### Building FROST ####
To build the kernel, you can type "make" in the "kernel" directory. You will then
get a file called "frost.krn" which is the kernel.
Building the init-process is very similar.
If you want to get a full iso with grub2 and a menu, type "./build_iso.sh" in
the "build"-directory. You will then get a file called "frost.iso" which is
the iso-image.
On some Linux distributions the script will fail because they contain
genisoimage from cdrkit instead of mkisofs from cdrtools. You can create
a link on genisoimage named mkisofs, but I strongly recommend installing
cdrtools instead of cdrkit. If cdrtools is not available on your distribution,
contact its maintainers.

#### Directory layout ####

./kernel/src/              The source of the kernel
./kernel/include/          The headers of the kernel
./build/                   Contains the build-scripts and the grub.cfg
./doc/                     Contains documentation for FROST
./init/                    Contains the source of the init-process
