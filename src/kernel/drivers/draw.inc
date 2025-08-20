[bits 16]
; INCLUDE

; Notes for feature development:
; - Always perserve data segment registers
; - Any function starting with "raw_" should have a macro for ease of use

; variables

background_color: dw 0

font:
    ; [...][WIDTH]
    db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x02 ; WHITE SPACE -> width 0 - 7
    db 0x18, 0x3C, 0x24, 0x24, 0x3C, 0x24, 0x24, 0x05 ; A -> width 0 - 5
    db 0x7C, 0x42, 0x42, 0x7C, 0x42, 0x42, 0x7C, 0x06 ; B -> width 0 - 6
    db 0x3E, 0x60, 0x40, 0x40, 0x40, 0x60, 0x3E, 0x06 ; C -> width 0 - 6
    db 0x7C, 0x42, 0x42, 0x42, 0x42, 0x42, 0x7C, 0x05 ; D -> width 0 - 6
    db 0x7E, 0x40, 0x40, 0x7E, 0x40, 0x40, 0x7E, 0x06 ; E -> width 0 - 6


; functions

drawBitmap: ; 8x8 (SKIPS 8TH BYTE) 
    ; params:
    ; ds:si -> bitmap pointer
    ; di -> draw address
    ; bl -> 256bit color
    ; return: si (8th BYTE)

    push es

    mov ax, Video_memory_segment
    mov es, ax

    mov cl, 7
    .read_byte:

        mov ch, 8
        mov al, [si]
        .read_bit:
            test al, 10000000b
            jz short .skip_bit

            ; draw bit
            mov byte [es:di], bl

            .skip_bit:
            shl al, 1
            inc di

        fastloop ch, .read_bit 

    ; .next_byte:
    
    add di, 312
    inc si

    fastloop cl, .read_byte

    pop es
    ret

raw_drawPixels:
    ; params:
    ; di -> draw address
    ; ax -> width (GROW RIGHT) ; 1 - 320 ; WARNING: IF 0 IT WILL CAUSE A OVERFLOW!
    ; bh -> height (GROW DOWN) ; 1 - 200 ; WARNING: IF 0 IT WILL CAUSE A OVERFLOW!!
    ; bl -> 256bit color

    push es

    mov dx, Video_memory_segment
    mov es, dx

    .draw_row:

        mov dx, ax
        .draw_column:

            mov byte [es:di], bl
            inc di

        fastloop dx, .draw_column

        add di, 320
        sub di, ax

    fastloop bh, .draw_row

    pop es
    ret

raw_setBackground: ; bx ; WORD ; 256bit color (example: 0x0404)

    push es
    
    mov ax, Video_memory_segment
    mov es, ax
    xor di, di ; 0x0000
    
    mov word [background_color], bx

    mov cx, 64000
    .fill:

        mov word [es:di], bx
        add di, 2

    fastloop cx, .fill

    pop es
    ret

getDrawAddress: ; Use igetDrawAddress if you are directly providing the X & Y (NASM will preprocess it)
    ; params:
    ; cx -> X ; 0 - 319 ; WORD
    ; dx -> Y ; 0 - 199 ; BYTE
    ; return: di (draw address)

    mov ax, 320
    mul dx
    add ax, cx
    mov di, ax

    ret