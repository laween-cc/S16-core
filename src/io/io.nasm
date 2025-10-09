[bits 16]
org 0x0500

; macros
%include "../include/misc.inc"

start:
    xor ah, ah
    mov al, 0x03
    int 0x10

    mov ah, 0x0E
    mov al, 'A'
    int 0x10

    halt

; variables
