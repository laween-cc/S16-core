[bits 16]
org 0x7C00

jmp 0x0000:start

start:
    cli

    ; data segments
    xor ax, ax ; 0x00000 (CS)
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

    ; stack
    xor ax, ax ; 0x0000
    mov ss, ax
    mov sp, 0x8000

    sti

    push es
    mov ax, 0x0800 ; int 13,2h loads into memory at ES:BX
    mov es, ax
    xor bx, bx ; 0x0000

    mov ah, 0x02

        ; params
        mov al, 1 ; number of sectors to read
        mov ch, 0 ; track
        mov cl, 2 ; starting sector
        mov dh, 0 ; head
        ; dl (drive number)

    int 0x13
    pop es

    jnc .success1
    mov ah, 0x0E
    mov al, '!' ; '!' to indicate a disk read error
    int 0x10
    hlt 
    .success1:

    ; set to 640x480 (VGA)
    mov ah, 0x00

        ; params
        mov al, 0x12
        
    int 0x10

    jmp 0x0800:0x0000 ; perform far jump to the kernel 

times 510 - ($ - $$) db 0
db 0x55, 0xAA ; MBR signature