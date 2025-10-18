# S16-core - disk services
S16-core provides some basic, but critical disk services to help!

## absolute disk read / write abstraction:
Interrupt: 22h

Parameters:
- ah - service
- dl - drive number (0 - 255)
- dh - logical sectors to read / write (1 - 128)
- cx - logical starting sector (can only address up to ~32MB)
- es:bx - memory buffer

Return:
- CF = 0 = success
- CF = 1 = failure **(READ "BIOS STATUS" BELOW)**
- al = bios status

Services:
- 02 - read to disk
- 03 - write to disk

Information:
- retries 3 times to read / write before failing
- each retry performs a disk reset (int 13,0h) and waits for ~110ms to allow floppies & slower storage devices to re-sync
- fixes the 64KiB segment boundary (ES:BX can point to anywhere and there will be no problem!)
- temporarily disables interrupts to ensure safer disk reads (restores to previous status once done)
- handles LBS to CHS conversion math reliably for majority of storage devices

Bios status:
- 00  no error
- 01  bad command passed to driver
- 02  address mark not found or bad sector
- 03  diskette write protect error
- 04  sector not found
- 05  fixed disk reset failed
- 06  diskette changed or removed
- 07  bad fixed disk parameter table
- 08  DMA overrun
- 09  DMA access across 64k boundary **(SHOULD NOT HAPPEN)**
- 0A  bad fixed disk sector flag
- 0B  bad fixed disk cylinder
- 0C  unsupported track/invalid media
- 0D  invalid number of sectors on fixed disk format
- 0E  fixed disk controlled data address mark detected
- 0F  fixed disk DMA arbitration level out of range
- 10  ECC/CRC error on disk read
- 11  recoverable fixed disk data error, data fixed by ECC
- 20  controller error (NEC for floppies)
- 40  seek failure
- 80  time out, drive not ready
- AA  fixed disk drive not ready
- BB  fixed disk undefined error
- CC  fixed disk write fault on selected drive
- E0  fixed disk status error/Error reg = 0
- FF  sense operation failed

Bytes per sector: 512 (relies on the BIOS following IBM's spec for int 13,2h)