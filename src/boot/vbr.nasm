[bits 16]
org 0x7C3E ; 0x7C00 + preserved fat12 meta data (0 - 61 bytes) offset by 1

; titles format:
; ===== major section =====
; ---- sub section ----

jmp 0x0000:start

; macros
%include "../include/misc.inc"
%include "../include/fat.inc"

%define disk_read_failure_code '0'
%define kernel_file_not_found_code '2'
%define fat12_got_bad_cluster_code '3'

start:
    cli
    
    xor ax, ax ; cs
    mov ds, ax
    mov es, ax

    mov ss, ax
    mov sp, 0x8000 ; reserve 1024 bytes

    sti 

    ; ===== load root directory =====
    ; numfats * logical_sectors_per_fat + reserved_logical_sectors

    mov bp, [0x7C00 + bpb_logical_sectors_per_fat]

    sal bp, 1 ; ax * 2^1 (bp * numfats)

    mov ax, [0x7C00 + bpb_reserved_logical_sectors]
    add bp, ax

    ; mov word [disk_read_lba_dump_offset], 0x8000
    mov di, 1
    call disk_read_lba

    ; ===== locate a kernel =====
    mov si, 0x8020
    mov cl, 16

    .read_entries:

        cmp byte [si], 0x00 ; end of directory
        je .failure

        ; check for kernel attributes    
        mov al, [si + 11]
        and al, 00000111b ; read-only, hidden, system
        cmp al, 00000111b ; 
        jne .skip_read

        ; ===== load the kernel =====

        ; ---- first data sector ----
        ; root_directory_starting_sector + ((root_directory_entries * 32) / bytes_per_logical_sector)
        mov bx, [0x7C00 + bpb_root_directory_entries]
        mov di, [0x7C00 + bpb_bytes_per_logical_sector] 

        sal bx, 5 ; bx * 2^5 (bx * 32)
        xor cl, cl

        ; log2
        .log2_loop_1:
            sar di, 1 ; di / 2^1 (di / 2)
            inc cl
            cmp di, 1
            jne .log2_loop_1
        mov byte [preserved_bytes_per_logical_sector_log2], cl

        sar bx, cl ; bx / 2^log2(bytes_per_logical_sector)
        add bx, bp ; bx + bp (bx + Root_directory_sector)
        mov word [preserved_first_data_sector], bx

        ; ---- reading the first cluster ----
        ; sector to read
        ; (n - 2) * logical_sectors_per_cluster + first_data_sector

        mov ax, [si + 26] ; cluster
        mov cl, [0x7C00 + bpb_logical_sectors_per_cluster] 
        sub ax, 2 ; ax - 2

        mul cl ; ax * cl
        ; mov bx, [preserved_first_data_sector]
        add ax, bx ; ax + bx (ax + first_data_sector)

        mov bp, ax
        xor ch, ch
        mov di, cx ; logical sectors per cluster
        mov word [disk_read_lba_dump_offset], 0x063E
        call disk_read_lba

        ; ---- load the main fat table ----
        ; read the main fat table into memory (0x0000:0x8200)
        mov bp, [0x7C00 + bpb_reserved_logical_sectors] 
        mov di, [0x7C00 + bpb_logical_sectors_per_fat]

        mov word [disk_read_lba_dump_offset], 0x8200
        call disk_read_lba

        ; ---- fat chain ----
        ; read the fat table and load all of the clusters
        mov word [disk_read_lba_dump_offset], 0x063E ; kernel start
        mov si, [si + 26]
        .read_fat:
            mov bx, si
            sar si, 1 ; si / 2^1 (si / 2)
            add bx, si
            add bx, 0x8200

            mov ax, [bx]
            test word [si + 26], 1 ; 0th bit
            jz .even_cluster

            .odd_cluster:

            ; (n >> 4) & 0x0FFF
            shr ax, 4
            and ax, 0x0FFF
            jmp .done_cluster

            .even_cluster:

            ; n & 0x0FFF
            and ax, 0x0FFF

            .done_cluster:
            cmp ax, 0x0FF8
            jge .enter_kernel
            cmp ax, 0x0FF7
            mov cl, fat12_got_bad_cluster_code
            je error_screen
            ; ignoring:
            ; reserved clusters
            ; free clusters

            mov word [preserved_current_cluster_number], ax

            ; ---- load cluster pointed to by fat ----
            ; sector to read
            ; (n - 2) * logical_sectors_per_cluster + first_data_sector
            sub ax, 2 ; ax - 2
            xor bh, bh
            mov bl, [0x7C00 + bpb_logical_sectors_per_cluster]
            mov di, bx
            mul bl ; ax * bl
            add ax, [preserved_first_data_sector] ; ax + first_data_sector
            mov bp, ax

            ; offset disk_read_lba_dump_offset by logical_sectors_per_cluster * bytes_per_logical_sector
            ; logical_sectors_per_cluster * 2^log2(bytes_per_logical_sector)
            mov cl, [preserved_bytes_per_logical_sector_log2]
            sal bx, cl
            add word [disk_read_lba_dump_offset], bx

            call disk_read_lba
        
            mov si, [preserved_current_cluster_number]
        jmp .read_fat ; continue the fat chain
        .enter_kernel:

        jmp 0x063E ; jump to kernel

    .skip_read:
    add si, 32 ; next entry
    loop cl, .read_entries

    .failure:
    mov cl, kernel_file_not_found_code
    ; jmp error_screen

error_screen: ; int 13h read failures / other errors
    ; cl -> acsii_error_code

    xor ah, ah ; reset video mode to clear screen
    mov al, 0x03
    int 0x10

    mov ah, 0x0E

    ; ===== error_message =====
    mov si, error_message
    mov ch, 12
    .write_1:
        mov al, [si]
        int 0x10
        inc si

    loop ch, .write_1

    ; ---- error code ----
    mov al, cl
    int 0x10

    ; ===== error_help_message =====
    mov si, error_help_message

    mov cl, 24
    .write_2:
        mov al, [si]
        int 0x10
        inc si

    loop cl, .write_2

    halt

; functions

disk_read_lba: ; built for the VBR (I don't recommend copy and pasting this)
    ; dumps the sectors into disk_read_lba_dump_offset
    ; es -> 0x0000
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

    mov ax, [0x7C00 + bpb_physical_sectors_per_track] 
    mov bl, [0x7C00 + bpb_number_of_heads] 

    ; I can't really optimize this part without making some other part of it slower or breaking support for some storage devices / majority of storage devices

    mul bl ; (SPT * HPC)

    mov byte [preserved_boot_drive], dl

    mov bx, ax
    mov ax, bp
    xor dx, dx
    div bx
    mov cx, ax

    mov ax, dx ; remainder
    mov bx, [0x7C00 + 0x018]
    xor dx, dx
    div bx
    inc dx ; remainder + 1
    mov dh, al

    shl cl, 6 ; zero 0 - 5 bits
    and dl, 00111111b ; mask 0 - 5 bits
    or cl, dl ; combine the bits

    ; ===== int 13,2h =====
    mov bx, [disk_read_lba_dump_offset]
    mov ax, di
    mov ah, 0x02
    mov dl, [preserved_boot_drive]

    int 0x13

    mov cl, disk_read_failure_code
    jc error_screen

    ret

    .disk_extensions:
    
    ; ===== int 13,42h =====

    ; load starting sector and sectors to read into DAP
    mov word [disk_address_packet + 0x02], di
    mov word [disk_address_packet + 0x08], bp

    mov ah, 0x42
    mov si, disk_address_packet
    int 0x13

    mov cl, disk_read_failure_code
    jc error_screen

    ret

; variables
error_message: db "Boot error: " ; length: 12
error_help_message: db 0x0A, 0x0D, "Ctrl+alt+del to reboot"; length: 24

preserved_current_cluster_number: dw 0
preserved_bytes_per_logical_sector_log2: db 0
preserved_first_data_sector: dw 0
preserved_boot_drive: db 0

disk_address_packet: ; for int 13,42h
    db 0x10 ; size of dap
    db 0 ; reserved byte
    dw 0 ; sectors to read
    dw 0x0000
disk_read_lba_dump_offset: dw 0x8000 ; offset
    dq 0 ; start of sector

times 448 - ($ - $$) db 0 ; pad to 448 bytes