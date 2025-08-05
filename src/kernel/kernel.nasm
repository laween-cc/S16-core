[bits 16]
org 0x7C00

kstart:
    cli

    ; data segments
    xor ax, ax ; 0x0000 (CS)
    mov ds, ax
    mov es, ax
    ; mov fs, ax
    ; mov gs, ax

    ; stack - 0x0000:0x8400
    mov ss, ax
    mov sp, 0x8400

    mov [boot_drive], dl ; save the boot drive

    sti



    jmp $

; variables

boot_drive: db 0