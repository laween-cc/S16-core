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
- ah = bios / non bios error code

Non bios error code:
- F4 - failed to reset disk during retry
- 8E - failed to get drive parameters

Information:
- handles 64KiB segment boundary
- retries 3 times before failing
- during each retry it does a 100ms delay after disk reset to ensure floppys can re-sync
- reads 512 bytes per sector (relies on bios following IBM's defined spec for int 13,2h)


## absolute disk write: