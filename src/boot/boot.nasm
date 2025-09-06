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
    
    ; .log_error_message:
    mov si, disk_error_message

    mov cl, 17
    .write_byte_1:
        mov al, [si]
        int 0x10
        inc si

    loop cl, .write_byte_1

    ; .log_error_help:
    mov si, error_message_help

    mov cl, 29
    .write_byte_2:
        mov al, [si]
        int 0x10
        inc si

    loop cl, .write_byte_2

    halt

; variables

disk_error_message: db "Disk read failure" ; length: 17
error_message_help: db 0x0A, 0x0D, "Ctrl + alt + del to restart" ; length: 29

times 448 - ($ - $$) db 0 ; PAD the left over space with 0