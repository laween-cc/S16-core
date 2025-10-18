# S16-core - disk services
S16-core provides some basic, but critical disk services to help!

## absolute disk read:
Interrupt: 25h

Parameters:
- dl - drive number
- dh - logical sectors to read (1 - 128)
- cx - logical starting sector (can only address up to 8GB)
- es:bx - dump address in memory

Return:
- CF = 0 = success
- CF = 1 = failure
- ah = bios error code

Information:
- fixes 64KiB segment boundary (ES:BX can point to any where)
- retries 3 times before failing
- during each retry it does a 100ms delay after disk reset to ensure floppys & slower disk devices  can re-sync
- temporally disables interrupts to ensure safer disk reads (restores to previous status once done)

Bytes_per_sector: 512

## absolute disk write: