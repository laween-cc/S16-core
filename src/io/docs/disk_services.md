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
- ah = error code

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