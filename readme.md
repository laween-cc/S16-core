# S16 - Simple 16bit operating system
A simple 16bit (real mode) operating system I created for the purpose of learning and fun.

## Legacy BIOS or UEFI?

S16 uses legacy BIOS and legacy bios functions (int 13,2h, int 10,0h, etc). If you want to use UEFI you'll have to use UEFI + CSM.

## S16 kernel

S16's kernel is pretty simple to be honest. Here is some information about it:

- The kernel gets copied to ``0x0000:0x7C00`` by the second stage boot.
- The kernel has a terminal and can execute ``.BIN`` files. (STILL WORKING ON IT)
- The kernel uses 320x200 VGA as its **main** video mode. Which is set by the MBR using ``int 10,0h``.
- The kernel provides drivers which it exposes to user applications using the IVT ``(int 41h)``. (STILL WORKING ON IT)
- The kernel uses fat16 for user applications. (STILL WORKING ON IT)

# Contributing

Contributing to S16 is a easy and fun way of learning! You can contribute by simply reporting bugs or code mistakes, but if you'd like to add features or fix documentation just follow the instructions down below:

- Fork repository
- Add your feature / fix / improvement
- Submit your code! (Create a pull request)
- Wait and sit back!

# License

[MIT](license)