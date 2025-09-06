[bits 16]
org 0x7C3E ; 0x7C00 + preserved fat12 meta data (0 - 62 bytes)

; macros
%include "../include/misc.inc"

jmp 0x0000:start

; notice: preserve the boot drive in dl so the kernel can save it

start:
    cli

    xor ax, ax ; cs
    mov ds, ax
    mov es, ax

    mov ss, ax
    mov sp, 0x7E00 ; reserve 512 bytes

    sti 

    jmp disk_error

    halt

disk_error: ; error handling for int 13 failure / other disk related failures

    xor ah, ah
    mov al, 0x03
    int 0x10

    mov ah, 0x0E
    mov si, disk_error_message

    ; .log_error:
    mov cl, 17
    .write_byte_1:
        mov al, [si]
        int 0x10
        inc si

    loop cl, .write_byte_1

    mov al, 0x0A
    int 0x10
    mov al, 0x0D
    int 0x10

    mov si, disk_error_message_help

    ; .log_error_help:
    mov cl, 27
    .write_byte_2:
        mov al, [si]
        int 0x10
        inc si

    loop cl, .write_byte_2

    halt

; variables

disk_error_message: db "Disk read failure" ; length: 17
disk_error_message_help: db "Ctrl + alt + del to restart" ; length: 27

times 448 - ($ - $$) db 0 ; PAD the left over space with 0