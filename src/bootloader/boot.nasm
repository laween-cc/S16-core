[bits 16]
org 0x7C00

; macros

%macro error 0 
    ; ONLY USE WHEN YOU HAVE SET VIDEO MODE TO 320x200

    ; push es
    
    mov ax, 0xA000
    mov es, ax
    xor di, di ; 0x0000
    mov cx, 64000 ; 64kb
    mov ax, 0x0404 ; Red color (2 bytes)

    .draw:

        mov word [es:di], ax
        add di, 2

    loop .draw

    ; pop es

%endmacro

; FIRST STAGE

jmp 0x0000:start

start:
    cli

    ; data segments
    xor ax, ax ; 0x0000 (CS)
    mov ds, ax
    mov es, ax
    ; mov fs, ax
    ; mov gs, ax

    ; stack
    xor ax, ax ; 0x0000
    mov ss, ax
    mov sp, 0x8000

    sti

    ; set video mode to 320x200 
    mov ah, 0x00

        ; params
        mov al, 0x13
        
    int 0x10

    ; push es
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
    ; pop es

    jnc .success1
    error
    hlt 
    .success1:

    jmp 0x0800:0x0000 ; perform far jump to the second stage

times 510 - ($ - $$) db 0
db 0x55, 0xAA ; MBR signature