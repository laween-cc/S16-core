# S16 - core
Hello!
This is S16's core, its purpose is to handle all the I/O stuff, setting up a absolute disk driver and a fat12 driver, and then of course load the kernel. Oh by the way this isn't only for S16's kernel, you can also use it for your own operating system (just know that this operates on a single-volume only, but may be extended to support other volumes if you handle it manually and don't use the more stricter services provided)!

## S16 boot process
Basic explaination

First thing that is loaded into memory (by bios) is the volume boot record! Then the volume boot record will:
- Read 1 sector of the root directory
- Read 16 entries in root to locate ``IO.SYS``
- Load the full 1KiB of ``IO.SYS`` to physical address ``0x0000:0x0500``
- Near jump to the start of ``IO.SYS`` (jump to ``0x0500``)

Second thing that is loaded into memory (by the volume boot record) is ``IO.SYS`` which will:
- Set up the absolute disk driver
- Set up the fat12 driver
- Open & read ``BOOT.SYT`` and load the specified kernel
- Far jump to the start of the kernel

Now the kernel is loaded successfully! 

## S16 boot requirements

- minimum usable memory - 128KiB
- max entries in root directory - less than or equal to 16
- CPU - any **potato**-class 8086 / i386 / x86 processor
- storage device - fat12 **ONLY!**
- firmware - legacy / UEFI + CSM
- where on disk - the volume should be the **FIRST** on disk

## S16 volume boot record

Simply loads ``IO.SYS`` from fat12 partition to physical address ``0x0000:0x0500``

[SPEC](src/boot/spec.txt)

## License

[MIT](license)