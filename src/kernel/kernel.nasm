[bits 16]
org 0x7C00

; macros

%include "macros/draw.inc"

%macro fastloop 2
    ; faster loop in 16bit real mode
    ; 1: register to use
    ; 2: jump address if not zero
    ; WARNING: Prone to overflow if 0 or negative

    dec %1
    jnz near %2

%endmacro

%macro sfastloop 2
    ; short version of fastloop
    ; faster loop in 16bit real mode
    ; 1: register to use
    ; 2: jump address if not zero
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

    ; stack - 0x0000:0x9000
    mov ss, ax
    mov sp, 0x9000
    ; mov bp, sp ; dont need yet

    mov byte [boot_drive], dl ; save the boot drive
    
    sti

    ; setBackground BLACK

    

    ; .loop:
    ; ...
    ; jmp short .loop

    jmp $

; functions

; ...

; drivers

%include "drivers/draw.inc"
%include "drivers/keyboard.inc"
%include "drivers/cursor.inc"

; variables

boot_drive: db 0 ; THIS SHOULD BE USED WHEN YOU NEED BOOT DRIVE!! (DL WILL NOW BE CONSIDERED A GENERAL PURPOSE REGISTER)

current_cursor_pos:
    dw 0 ; X
    db 0 ; Y
    db 0 ; IGNORE! (make sure nothing changes this byte)

background_color: dw 0

font:
    times 32 * 8 db 0x00 ; Unsupported stuff
    ; [...][WIDTH] 
    db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x03 ; SPACE
    db 0x80, 0x80, 0x80, 0x80, 0x80, 0x00, 0x80, 0x03 ; ! 

    times 8 db 0x00 ; DEL

term_input_buffer:
    ; 0 - 255: [ACSII]
    times 0xFF db 0

term_input_buffer_metadata:
    ; 0 - 255: [WIDTH]
    times 0xFF db 0