[bits 16]
org 0x05CD

; titles format:
; ===== major section in label =====
; ===== sub section in label =====

; io error codes:
;

; disk failure codes: (uses bios)
; 0x00  no error
; 0x01  bad command passed to driver
; 0x02  address mark not found or bad sector
; 0x03  diskette write protect error
; 0x04  sector not found
; 0x05  fixed disk reset failed
; 0x06  diskette changed or removed
; 0x07  bad fixed disk parameter table
; 0x08  DMA overrun
; 0x09  DMA access across 64k boundary
; 0x0A  bad fixed disk sector flag
; 0x0B  bad fixed disk cylinder
; 0x0C  unsupported track/invalid media
; 0x0D  invalid number of sectors on fixed disk format
; 0x0E  fixed disk controlled data address mark detected
; 0x0F  fixed disk DMA arbitration level out of range
; 0x10  ECC/CRC error on disk read
; 0x11  recoverable fixed disk data error, data fixed by ECC
; 0x20  controller error (NEC for floppies)
; 0x40  seek failure
; 0x80  time out, drive not ready
; 0xAA  fixed disk drive not ready
; 0xBB  fixed disk undefined error
; 0xCC  fixed disk write fault on selected drive
; 0xE0  fixed disk status error/Error reg = 0
; 0xFF  sense operation failed

; structure:
; 0x0500 - 0x07CD is loaded by the VBR
; 0x0500 -> BPB
; 0x053E -> boot drive
; 0x053F -> root directory logical starting sector
; 0x0540 -> root directory logical sectors
; 0x0541 -> first logical data sector
; 0x0542 -> disk read abstraction (int 0x20)
; 0x05CD -> IO.SYS

; macros
%include "include/misc.inc"
%include "include/fat.inc"

start:
    ; ===== set up =====
    ; ES is already set by the VBR
    ; DS is already set by the VBR
    ; reusing the VBR's stack
    ; VBR already copied the BPB above us
    ; root directory logical starting sector is already in a known address
    ; root directory logical sectors is already in a known address
    ; first logical data sector is alraedy in a known address
    


    halt

