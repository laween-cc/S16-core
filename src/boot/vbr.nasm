[bits 16]
org 0x7C3E ; 0x7C00 + 62 (past the BPB)

; titles format:
; ===== major section in label =====
; ===== sub section in label =====

; vbr error codes:
; 0xAE -> Failed to locate IO.SYS

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

; what the VBR does: (not in order)
; stores boot drive at a known address
; exposes a reliable and safe disk read abstraction through IVT (int 0x20)
; stores root directory logical starting sector at a known address
; stores root directory logical sectors at a known address
; stores first logical data sector at a known address
; loads the entire root directory into memory
; locates IO.SYS on disk
; loads one sector of IO.SYS in memory
; copies the BPB above IO.SYS in memory
; jumps to IO.SYS in memory

; macros
%include "../include/misc.inc"

start:
    cli

    xor ax, ax
    mov ds, ax
    mov es, ax

    mov ss, ax
    mov sp, 0x7C00

    ; ===== store the boot drive =====
    mov byte [boot_drive], dl ; DX is now free to use

    sti

    ; ===== copy disk_read_abstraction to a known address =====
    ; 0x0742
    mov si, disk_read_abstraction
    mov di, 0x0542
    mov cx, disk_read_abstraction_end - disk_read_abstraction
    ; cld
    repe movsb ; using movsb to save bytes

    ; ===== expose disk_read_abstraction =====
    ; int 20h
    mov word [0x20 * 4], 0x0542
    mov word [0x20 * 4 + 2], 0x0000

    ; ===== get the root directory logical starting sector ====
    ; reserved_logical_sectors + (2 (numfats) * logical_sectors_per_fat)
    mov al, [0x7C00 + 0x016] ; logical sectors per fat
    sal al, 1
    add al, [0x7C00 + 0x00E] ; reserved logical sectors
    mov byte [root_directory_logical_starting_sector], al

    ; ===== get the root directory logical sectors =====
    ; (root_directory_entires * 32) / bytes_per_logical_sector
    mov bx, [0x7C00 + 0x011] ; root directory entries
    mov dx, [0x7C00 + 0x00B] ; bytes per logical sector
    sal bx, 5

    xor cl, cl
    .log2_loop_1:
        sar dx, 1
        inc cl
        cmp dx, 1
        jne .log2_loop_1

    sar bx, cl
    xor bh, bh
    mov byte [root_directory_logical_sectors], bl

    ; ===== read root directory into memory (all of it) =====
    mov dl, [boot_drive]
    mov byte [dap_starting_sector], al
    mov byte [dap_sectors_to_read], bl
    mov si, disk_address_packet
    int 0x20

    jc error_screen

    ; ===== locate IO.SYS =====
    mov dx, bx
    sal dx, cl
    sar dx, 5
    mov si, 0x7E00 + 32

    .IO_SYS:
        cmp byte [si], 0x00 ; end (stop reading)
        je .IO_SYS_failure

        mov cx, 11
        mov di, io_file_name
        ; cld
        repe cmpsb ; using cmpsb to save bytes
        jnz .IO_SYS_skip

        ; ===== read the first cluster into memory =====
        ; first_logical_data_sector = root_directory_logical_sectors + root_directory_logical_starting_sector
        ; (N - 2) * logical_sectors_per_cluster + first_logical_data_sector

        add bl, al ; sense we're using fat12.. this will fit!
        mov byte [first_logical_data_sector], bl

        mov ax, [si + 15]
        sub ax, 2
        mov dh, [0x7C00 + 0x00D] ; logical sectors per cluster
        mul dh
        add ax, bx

        mov dl, [boot_drive]
        mov byte [dap_sectors_to_read], 1
        mov word [dap_starting_sector], ax
        mov word [dap_offset], 0x05CD
        mov si, disk_address_packet
        int 0x20

        jc error_screen

        ; ===== copy the VBR above IO.SYS & stored variables in memory =====
        mov si, 0x7C00
        mov di, 0x0500
        mov cx, 61
        ; cld
        repe movsb ; using movsb to save bytes

        ; ===== jump to IO.SYS =====
        jmp 0x05CD

    .IO_SYS_skip:
    add si, 32
    loop dx, .IO_SYS

    .IO_SYS_failure:
    mov ah, 0xAE

error_screen:
    ; ah -> error code

    ; ===== error code (hex) to acsii =====
    mov al, ah
    shr ah, 4 ; shift bits 7 - 4 to bits 0 - 4 and zero out bits 7 - 4
    and al, 00001111b ; zero out bits 7 - 4

    cmp ah, 9
    jle .digit_1
    add ah, 7 ; add 7 to bring it towards the A - Z (in acsii)
    .digit_1:
    add ah, '0'

    cmp al, 9
    jle .digit_2
    add al, 7 ; add 7 to bring it towards the A - Z (in acsii)
    .digit_2:
    add al, '0'

    mov bx, ax

    ; ===== clear the screen (reset video mode) =====
    xor ah, ah 
    mov al, 0x03
    int 0x10

    ; ===== error message =====
    mov ah, 0x0E
    mov si, boot_error_message
    mov ch, 14

    .error_message_loop:
        mov al, [si]
        int 0x10
        inc si

    loop ch, .error_message_loop

    ; ===== error code =====
    mov al, bh
    int 0x10
    mov al, bl
    int 0x10

    halt

; exposed functions

disk_read_abstraction:
    ; dl -> boot drive
    ; ds:si -> disk address packet
    ; return:
    ; CF = 0 = success
    ; CF = 1 = failure
    ; AH = disk operation status
    ; AH = 0x42 = int 13,8h failure during legacy read
    
    push bx
    push ax
    push dx
    push cx
    push es
    push di

    ; ===== can we use disk extensions? =====
    mov ah, 0x41
    mov bx, 0x55AA
    int 0x13

    jnc .disk_extensions
    .disk_legacy:

    ; ===== get disk information =====
    mov al, dl ; preserve the boot drive
    mov ah, 0x08
    int 0x13
    mov dl, al
    mov bh, 0x42 ; In case of failure

    jc .quit ; CF is already set 

    inc dh ; we need number of heads to start from 1
    and cl, 00111111b ; make sure we dont use the high cylinder bits (7 - 6)

    ; ===== LBS to CHS =====
    push dx ; preserve the boot drive
    xor ah, ah
    mov al, dh
    mul cl ; (HPC * SPT)

    ; cylinder
    ; LBS / (HPC * SPT)
    xor dx, dx
    mov bx, ax
    mov ax, [si + 0x08]
    div bx
    mov bx, ax

    ; head
    ; LBS % (HPC * SPT) / SPT
    mov ax, dx
    xor dx, dx
    div cl
    
    mov cx, bx ; put cylinder in the right place

    ; sector
    ; LBS % (HPC * SPT) % SPT + 1
    inc ah ; sector starts from 1

    ; put sector in the right place
    shl cl, 6 ; shift bits 1 - 0 to 7 - 6 and zero out bits 5 - 0
    and ah, 00111111b ; zero out bits 7 - 6
    or cl, ah ; combine the bits

    pop dx  
    mov dh, al ; put head in the right place

    ; ch = low bits of cylinder
    ; cl bits 7 - 6 = high bits of cylinder 
    ; cl bits 5 - 0 = sector number
    ; dh = head

    ; ===== int 13,2h =====
    mov ax, [si + 0x06] ; segment
    mov es, ax
    mov al, [si + 0x02] ; sectors to read

    mov di, 3 ; retry counter
    .disk_legacy_start:
    mov bx, [si + 0x04] ; offset

    mov ah, 0x02
    int 0x13
    mov bh, ah ; disk operation status

    jnc .quit

    ; ---- retry for int 13,2h ----
    dec di
    jz .quit ; CF is already set

    xor ah, ah
    int 0x13
    mov bh, ah ; disk operation status

    jc .quit ; CF is already set

    jmp .disk_legacy_start
    .disk_extensions:

    mov bl, 3 

    .disk_extensions_start:
    ; ===== disk extensions (int 13,42h) =====
    mov ah, 0x42
    ; ds:si -> dap
    int 0x13
    mov bh, ah ; disk operation status

    jnc .quit

    ; ---- retry for int 13,42h ----
    dec bl
    jz .disk_legacy ; try the legacy method

    ; ---- reset disk ----
    xor ah, ah 
    int 0x13
    mov bh, ah ; disk operation status

    jc .quit ; CF is already set

    jmp .disk_extensions_start

    .quit: ; make sure bh = disk operation status!
    pop di
    pop es
    pop cx
    pop dx
    pop ax
    mov ah, bh ; disk operation status
    pop bx
    iret
disk_read_abstraction_end:
 
; variables

io_file_name: db "IO      " ; length: 8
io_extension: db "SYS" ; length: 3
boot_error_message: db "Boot error: 0x" ; length: 14

disk_address_packet:
    db 0x10 ; size
    db 0 ; reserved
dap_sectors_to_read: dw 1        
dap_offset: dw 0x7E00 
dap_segment: dw 0x0000
dap_starting_sector: dq 0

times 446 - ($ - $$) db 0 ; pad to 446 bytes