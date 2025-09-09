[bits 16]
org 0x7C3E ; 0x7C00 + preserved fat12 meta data (0 - 62 bytes)

jmp 0x0000:start

; macros
%include "../include/misc.inc"

start:
    cli

    xor ax, ax ; cs
    mov ds, ax
    mov es, ax

    mov ss, ax
    mov sp, 0x7E00 ; reserve 512 bytes

    ; mov byte [preserved_boot_drive], dl

    sti 

    ; root directory starting sector
    ; numfats * logical_sectors_per_fat + reserved_logical_sectors

    ; mov dl, [0x7C00 + 0x010] ; number of fats
    mov ax, [0x7C00 + 0x016] ; logical sectors per fat

    sal ax, 1 ; ax * 2^1

    mov bx, [0x7C00 + 0x00E] ; reserved logical sectors
    add ax, bx

    mov word [preserved_root_sector], ax

    ; root directory sectors
    ; (root_directory_entires * 32) / 2^log2(bytes_per_logical_sector)

    mov bx, [0x7C00 + 0x00B] ; bytes per logical sector
    mov di, [0x7C00 + 0x011] ; Root directory entires

    sal di, 5 ; di * 2^5 (di * 32)

    ; log2(bytes_per_logical_sector)
    xor cl, cl
    .log2_loop_1:
    sar bx, 1 ; dx / 2^1 (dx / 2)
    inc cl
    cmp bx, 1
    jne .log2_loop_1

    sar di, cl ; di / 2^log2(bytes_per_logical_sector)

    ; mov word [preserved_root_sectors], di

    ; do we have int 13h extensions?
    mov ah, 0x41
    ; mov dl, [preserved_boot_drive]
    mov bx, 0x55AA 
    int 0x13

    jnc .disk_extensions

    ; covnert LBA to CHS

    ; use int 13,2h instead. Load the sectors to 0x0000:0x8000

    ; locate S16.SYS

    .disk_extensions:

    ; load information into the DAP

    ; read the sectors to 0x0000:0x8000

    ; .skip_2:

    ; locate S16.SYS

    halt

preserved_root_sector: dw 0
; preserved_root_sectors: dw 0
preserved_boot_drive: db 0

times 448 - ($ - $$) db 0 ; PAD the left over space with 0