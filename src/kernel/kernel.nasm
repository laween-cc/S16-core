[bits 16]
org 0x7C00

; macros

%include "macros/draw.inc"
%include "macros/cursor.inc"

%macro fastloop 2
    ; faster loop in 16bit real mode
    ; 1: register to use
    ; 2: jump address if not zero (SHORT)
    ; WARNING: Prone to overflow if 0 or negative

    dec %1
    jnz short %2

%endmacro

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

    mov byte [boot_drive], dl ; save the boot drive

    sti

    setBackground RED

    getDrawAddress 10, 10
    mov ax, 300
    mov bh, 180
    mov bl, BLUE

    call raw_drawPixels


    jmp $

; variables

boot_drive: db 0 ; THIS SHOULD BE USED WHEN YOU NEED BOOT DRIVE!! (DL WILL NOW BE CONSIDERED A GENERAL PURPOSE REGISTER)

; functions

; ...

; drivers

%include "drivers/draw.inc"
%include "drivers/cursor.inc"