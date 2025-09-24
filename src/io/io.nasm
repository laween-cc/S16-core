[bits 16]
org 0x063E

; macros
%include "../include/misc.inc"

io_start:
    ; stack is already set by vbr
    ; segments are already set by vbr
    ; we're basically just using what the vbr already set

    mov byte [boot_drive], dl ; save the boot drive

    xor ah, ah
    mov al, 0x03
    int 0x10

    mov ah, 0x0E
    mov al, 'I'
    int 0x10

    halt

; functions

; variables

boot_drive: db 0

