[bits 16]
org 0x7C00

; characters
%define WHITE_SPACE 0x00
%define A 0x08

; colors
%define BLACK 0x00 
%define BLUE 0x01
%define GREEN 0x02
%define TEAL 0x03
%define RED 0x04
%define PURPLE 0x05
%define ORANGE 0x06

; macros

%macro drawPixels 5
    ; 1: X
    ; 2: Y
    ; 3: width
    ; 4: height
    ; 5: color

    mov ax, %1
    mov dx, %2
    mov si, %3
    mov bl, %4
    mov bh, %5

    call raw_drawPixels
%endmacro

%macro setBackground 1
    ; 1: color

    mov al, %1

    call raw_setBackground
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

    mov [boot_drive], dl ; save the boot drive

    sti

    setBackground BLUE

    drawPixels 0, 190, 320, 10, RED

    jmp $

; variables

boot_drive: db 0 ; THIS SHOULD BE USED WHEN YOU NEED BOOT DRIVE!! (DL WILL NOW BE CONSIDERED A GENERAL PURPOSE REGISTER)
background_color: db 0

font:
    db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ; WHITE SPACE
    db 0x0C, 0x1E, 0x12, 0x12, 0x12, 0x1E, 0x12, 0x00 ; A
     

; functions

raw_drawPixels:
    ; params:
    ; ax -> X (COLUMN)
    ; dx -> Y (ROW)
    ; si -> width (GROWS RIGHT)
    ; bl -> height (GROWS DOWN)
    ; bh -> 256bit color

    push es
    push ax

    mov ax, 0xA000
    mov es, ax

    mov ax, 320
    dec dx ; decrement Y because we start drawing FROM 0 and NOT 1
    ; push dx
    imul dx
    mov di, ax

    ; pop dx
    pop ax
    add di, ax

    ; AX
    ; DX

    inc bl
    mov cl, bl
    xor ch, ch ; 0x00
    .draw:

        push cx
        mov cx, si
        .draw_columns:
            mov byte [es:di], bh
            inc di
        loop .draw_columns        
        pop cx

    add di, 320
    sub di, si
    loop .draw

    pop es
    ret


raw_setBackground: ; al (256bit color)

    push es
    push ax
    mov ax, 0xA000
    mov es, ax
    mov di, 0x0000
    mov cx, 64000
    pop ax
    mov [background_color], al
    mov ah, al

    .fill:

        mov word [es:di], ax
        add di, 2

    loop .fill

    pop es
    ret