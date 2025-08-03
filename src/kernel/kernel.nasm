[bits 16]
org 0x0000 ; 0x0800:0x0000

kstart:
    cli

    ; data segments
    mov ax, cs ; 0x0800
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

    ; stack
    xor ax, ax ; 0x0000
    mov ss, ax
    mov sp, 0x8400    

    mov [boot_drive], dl ; save the boot drive

    sti


    jmp $

; variables

boot_drive: db 0