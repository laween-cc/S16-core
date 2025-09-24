[bits 16]
org 0x7C3E ; 0x7C00 + preserved fat12 meta data (0 - 61 bytes) offset by 1

; titles format:
; ===== major section =====
; ---- sub section ----

jmp 0x0000:start

; macros
%include "../include/misc.inc"
%include "../include/fat.inc"

start:
    cli
    
    xor ax, ax ; cs
    mov ds, ax
    mov es, ax

    mov ss, ax
    mov sp, 0x7C00

    mov byte [preserved_boot_drive], dl

    sti 

    ; ===== load IO.SYS =====

    ; ---- get the root_directory_logical_sector ----
    ; numfats * logical_sectors_per_fat + reserved_logical_sectors

    mov bp, [0x7C00 + bpb_logical_sectors_per_fat]

    sal bp, 1 ; bp * 2^1

    mov ax, [0x7C00 + bpb_reserved_logical_sectors]
    add bp, ax ; logical sector to read
    
    ; ---- read one sector ----
    ; mov word [disk_read_lba_dump_offset], 0x7E00
    mov di, 1
    call vbr_disk_read_lba_abstraction

    ; ---- log2 bytes_per_logical_sector ----
    mov ax, [0x7C00 + bpb_bytes_per_logical_sector]
    xor cl, cl

    .log2_loop_1:
        sar ax, 1 ; ax / 2^1 (ax / 2)
        inc cl
        cmp ax, 1
        jne .log2_loop_1

    mov byte [preserved_bytes_per_logical_sector_log2], cl

    ; ---- root directory logical sectors ----
    ; (root_directory_entries * 32 + bytes_per_logical_sector - 1) / bytes_per_logical_sector
    mov di, [0x7C00 + bpb_root_directory_entries]
    sal di, 5 ; di * 2^5 (di * 32)
    mov bx, [0x7C00 + bpb_bytes_per_logical_sector]
    dec bx
    add di, bx
    sar di, cl

    ; ---- read bytes_per_logical_sector / 32 entries (1 sector worth of entries) ----
    mov cx, [0x7C00 + bpb_bytes_per_logical_sector]
    sar cx, 5

    xor dh, dh

    .read_entries:
    mov si, 0x7E00
    .read_entry:

        cmp byte [si], 0x00 ; no more files marker
        je .failure

       ; compare the file name with IO.SYS
        cmp word [si], "IO"
        jne .skip_read_entry
        cmp word [si + 2], "  "
        jne .skip_read_entry
        cmp word [si + 4], "  "
        jne .skip_read_entry
        cmp word [si + 6], "  "
        jne .skip_read_entry
        cmp word [si + 8], "SY"
        jne .skip_read_entry
        cmp byte [si + 10], "S"
        jne .skip_read_entry

        ; ===== load IO.SYS (one sector!) =====

        ; ---- first logical data sector ----
        ; root_directory_logical_starting_sector + root_directory_logical_sectors
        add bp, di

        ; ---- load one sector from the cluster ---- 
        ; (n - 2) *  logical_sectors_per_cluster + first_logical_data_sector
        mov ax, [si + 26] ; cluster
        mov bl, [0x7C00 + bpb_logical_sectors_per_cluster]
        sub ax, 2

        mul bl ; ax * bl

        add bp, ax ; logical sector to read

        mov di, 1 ; logical sectors to read

        mov word [disk_read_lba_dump_offset], 0x063E
        call vbr_disk_read_lba_abstraction

        ; ---- jump to IO.SYS ----
        jmp 0x063E

    .skip_read_entry:
    add si, 32
    loop cx, .read_entry

    cmp dh, 1
    je .failure

    ; ---- read the entire root directory into 0x7E00 ----

    dec di ; - 1 sectors to read (we already read 1 sector)
    inc bp ; + 1 starting sector (we already read 1 sector)
    
    ; mov word [disk_read_lba_dump_offset], 0x7E00
    call vbr_disk_read_lba_abstraction

    mov ax, di
    mov cl, [preserved_bytes_per_logical_sector_log2]
    sal ax, cl
    mov cx, ax

    dec bp ; .read_entry relys on BP being the starting sector of the root directory
    inc di ; .read_entry relys on DI being the amount of sectors the root directory has

    mov dh, 1
    jmp .read_entries
    
    .failure:
    mov si, error_no_IO_SYS
    mov ch, 30

error_screen: ; int 13h read failures / other errors
    ; si -> error_message
    ; ch -> length

    xor ah, ah ; reset video mode to clear screen
    mov al, 0x03
    int 0x10

    mov ah, 0x0E

    ; ===== error_message =====
    .write_1:
        mov al, [si]
        int 0x10
        inc si

    loop ch, .write_1

    ; ===== error_help_message =====
    mov si, error_help_message

    mov cl, 28
    .write_2:
        mov al, [si]
        int 0x10
        inc si

    loop cl, .write_2

    halt

; functions

vbr_disk_read_lba_abstraction: ; built for the VBR (I don't recommend copy and pasting this)
    ; dumps the sectors into disk_read_lba_dump_offset
    ; es should be 0x0000
    ; dl -> boot drive
    ; di -> sectors to read
    ; bp -> starting sector

    ; check for int 13h extensions
    mov ah, 0x41
    mov bx, 0x55AA
    int 0x13

    jnc .disk_extensions

    ; otherwise we need to use int 13,2h

    ; ===== LBA -> CHS =====
    ; cylinder = lba / (hpc * spt)
    ; temp_remainder = lba % (hpc * spt)
    ; head = temp / spt
    ; sector = temp % spt + 1

    push es
    push di
    mov ah, 0x08
    int 0x13

    ; cl = spt
    ; dh = hpc

    mov si, error_disk_read
    mov ch, 17
    jc error_screen

    inc dh ; make it the actual number of heads (because it starts from 0 - X)
    and cl, 00111111b ; zero out bits 7 - 6

    xor ah, ah
    mov al, dh
    mul cl ; ax * cl

    ; cylinder
    xor dx, dx
    mov bx, ax
    mov ax, bp ; LBA
    div bx ; dx:ax / bx
    mov bx, ax

    ; head
    mov ax, dx ; remainder (temp)
    xor dx, dx
    div cl ; dx:ax / cl
    mov dh, al

    mov cx, bx ; put cylinder in right register for int 13,2h

    ; sector
    inc ah

    shl cl, 6 ; zero bits 0 - 5
    and ah, 00111111b ; zero bits 7 - 6
    or cl, ah ; combine the bits
    pop di
    pop es

    mov dl, [preserved_boot_drive] ; restore the boot drive
    mov bx, [disk_read_lba_dump_offset]
    mov ax, di
    mov ah, 0x02

    int 0x13

    mov si, error_disk_read
    mov ch, 17
    jc error_screen

    ret

    .disk_extensions:
    ; ===== int 13,42h =====

    ; load starting sector and sectors to read into DAP
    mov word [disk_address_packet + 0x02], di
    mov word [disk_address_packet + 0x08], bp
    ; mov word [disk_address_packet + 0x06], es

    mov ah, 0x42
    mov si, disk_address_packet
    int 0x13

    mov si, error_disk_read
    mov ch, 17
    jc error_screen

    ret

; variables
error_disk_read: db "Disk read failure" ; length: 17
error_no_IO_SYS: db "Failed to find IO.SYS on disk?" ; length: 30 
error_help_message: db 0x0A, 0x0D, "Ctrl + alt + del to reboot"; length: 28

preserved_bytes_per_logical_sector_log2: dw 0
preserved_boot_drive: db 0

disk_address_packet: ; for int 13,42h
    db 0x10 ; size of dap
    db 0 ; reserved byte
    dw 0 ; sectors to read
disk_read_lba_dump_offset: dw 0x7E00 ; offset
    dw 0x0000 ; segment 
    dq 0 ; start of sector

times 448 - ($ - $$) db 0 ; pad to 448 bytes