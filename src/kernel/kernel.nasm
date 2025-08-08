[bits 16]
org 0x7C00

; macros

%include "macros/draw.nasm"

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
    ; mov bp, sp ; dont need yet

    mov [boot_drive], dl ; save the boot drive

    sti

    setBackground RED

    drawPixels 10, 10, 300, 180, BLUE

    jmp $

; variables

boot_drive: db 0 ; THIS SHOULD BE USED WHEN YOU NEED BOOT DRIVE!! (DL WILL NOW BE CONSIDERED A GENERAL PURPOSE REGISTER)

; functions

; ...

; drivers

%include "drivers/draw.nasm"