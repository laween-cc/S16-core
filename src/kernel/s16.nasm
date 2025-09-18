[bits 16]
org 0x0600

; macros
%include "../include/misc.inc"

kstart:
    cli

    mov sp, 0x0A00 ; reserve 1024 bytes for stack

    ; store boot_drive
    mov byte [boot_drive], dl

    sti

    xor ah, ah
    mov al, 0x03
    int 0x10

    mov ah, 0x0E
    mov al, 'K'
    int 0x10    

    halt


; variables
boot_drive: db 0