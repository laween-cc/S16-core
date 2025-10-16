# S16-core - disk services
S16-core provides some basic, but critical disk services to help!

## absolute disk read:
Interrupt: 25h

Parameters:
- al - drive number
- cx - logical sectors to read
- dx - logical starting sector
- es:bx - dump address in memory

Return:
- CF = 0 = success
- CF = 1 = failure
- ah = bios / non bios error code

Non bios error code:
- F4 - failed to reset disk during retry
- 8E - failed to get drive parameters

Information:
- Handles large sector reads at once
- Retries 3 times (resets disk every retry)
- Handles 64KiB segment boundary
- Loads 512 bytes per sector (relies on BIOS following the IBM spec for int 13,2h)

## absolute disk write:
Interrupt: 26h

Parameters:
- al - drive number
- cx - logical sectors to write
- dx - logical starting sector
- es:bx - addess in memory of content to write

Return:
- CF = 0 = success
- CF = 1 = failure
- ah = error code