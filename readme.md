# S16 - Simple 16bit operating system
S16 is a single-volume operating system inspired by MS/IBM-DOS, but uses fat12 and throws out all of the junk and tries its best to be modern!

It's purpose is to be:
- small - fits in around ~1.5KiB currently (on disk).
- performant - trying my best to optimize it!
- simple - no weird complex booting or requirements
- effective - does exactly what a single-volume operating system **SHOULD** do!

Use cases:
- embedded
- learning - great for teaching beginners how to make a real operating system!
- retro computing fun - feels like you're using MS/IBM-DOS again!
- hobby projects - maybe you were building little MS/IBM-DOS apps, but got tired of the same thing and wanted something new!

S16 can be booted from pretty much every storage device (as long as it uses proper fat12).

Oh and S16's ``IO.SYS`` is only 1KiB and not ~40KiB like MS-DOS!

# S16 requirements

- minimum usable memory - 80KiB
- max entries in root directory - less than or equal to 16
- CPU - any **potato**-class 8086 / i386 / x86 processor
- storage device - fat12 **ONLY!**
- firmware - legacy / UEFI + CSM

# S16 volume boot record

Simply loads ``IO.SYS`` from fat12 partition to physical address ``0x0000:0x0500``

[SPEC](src/boot/spec.txt)

# License

[MIT](license)