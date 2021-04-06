This is a simple kernel driver that prints a hello message when loaded
and a good-bye message when unloaded. The Makefile assume cross-compilation.

To prepare the kernel for module compilation:
$ make prepkernel

To build the driver:
$ make driver

To clean the driver sources:
$ make clean

The module can be loaded with insmod.
For modprobe loading, do this first:

[Target] # nc -l -p 5600 > simple.ko
[Host] nc 192.168.0.103 5600 < ./simple.ko
[Target] # insmod ./simple.ko
Look for the "Hello world 1" message when the driver is loaded.
tail -f /var/log/messages

There will be another message printed when the driver is unloaded.
[Target] # rmmod simple

The driver version magic shall match the kernel magic number, which means
the driver shall be built with the same tools and configs as the kernel.

[Target] # modinfo /lib/modules/3.19.12-mitx/kernel/crypto/simple.ko
filename: /lib/modules/3.19.12-mitx/kernel/crypto/simple.ko
license:        GPL
srcversion:     546A198694B6ABE568FFE54
depends:
vermagic:       3.19.12-mitx SMP mod_unload modversions MIPS32_R2 32BIT
[Target] # uname -a
Linux tclient 3.19.12-mitx #0 SMP Fri Jun 17 22:59:04 AST 2016 mips
GNU/Linux

Note that not all compiler warnings are enabled by default.  Build the
kernel with "make EXTRA_CFLAGS=-W" to get the full set.

The kernel provides several configuration options which turn on debugging
features; most of these are found in the "kernel hacking" submenu.  Several
of these options should be turned on for any kernel used for development or
testing purposes.  In particular, you should turn on:

 - ENABLE_WARN_DEPRECATED, ENABLE_MUST_CHECK, and FRAME_WARN to get an
   extra set of warnings for problems like the use of deprecated interfaces
   or ignoring an important return value from a function.  The output
   generated by these warnings can be verbose, but one need not worry about
   warnings from other parts of the kernel.

 - DEBUG_OBJECTS will add code to track the lifetime of various objects
   created by the kernel and warn when things are done out of order.  If
   you are adding a subsystem which creates (and exports) complex objects
   of its own, consider adding support for the object debugging
   infrastructure.

 - DEBUG_SLAB can find a variety of memory allocation and use errors; it
   should be used on most development kernels.

 - DEBUG_SPINLOCK, DEBUG_ATOMIC_SLEEP, and DEBUG_MUTEXES will find a
   number of common locking errors.

Building the module natively with linux-headers installed on target
===================================================================

When the kernel deb package linux-headers is cross-built on x86 host,
due to a bug in deb-pkg, fixdep is included from host instead of the target.
This will lead to errors "fixdep: Exec format error" when you build the
external module on target. Use the following patch to rebuild fixdep
and other tools on target after linux-headers is installed:
 
sudo apt-get install -y build-essential bc bison flex libssl-dev
cd /usr/src/linux-headers-`uname -r`
sudo patch -p1 < /tmp/headers-debian-byteshift.patch
sudo make scripts
```
