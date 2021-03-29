```
To build the kernel and modules:

Untar the toolchain where the Makefile can find it. In the Makefile, set the
CROSS prefix wrt the toolchain. Set INST_MOD_DIR where the distro will look for
the modules. Modern distros usually have them in /usr/lib/modules.

Build the kernel.

$ make all 2>&1 | tee /tmp/make.log

For the kernels outside git, specify the KERNEL version explicitly:

$ make KERNEL=5.4 all

If you need to modify the kernel configuration, for ex. to add drivers,
run the 'reconfigure' target after the 'kernel' target:
$ make kernel 2>&1 | tee /tmp/make.log
$ make reconfigure
$ make modules
$ make package
Optional: prepare deb packages
$ make deb

The build takes place in ./build.
The 'make package' makes the installation tarball in the current dir.
The package contains the kernel and the modules.

Untar the package on target:

[host] $ pv package.tar.gz | nc -l -p 5600
[target] $ nc 192.168.30.143 5600 | sudo tar xpzf - -C /

```
