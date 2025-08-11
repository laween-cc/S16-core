[bits 16]
; INCLUDE

; Notes for feature development:
; Always perserve data segment registers

; variables

background_color: db 0

font:
    ; [...][WIDTH]
    db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x07 ; WHITE SPACE -> width 0 - 7
    db 0x18, 0x3C, 0x24, 0x24, 0x3C, 0x24, 0x24, 0x05 ; A -> width 0 - 5
    db 0x7C, 0x42, 0x42, 0x7C, 0x42, 0x42, 0x7C, 0x06 ; B -> width 0 - 6
    db 0x3E, 0x60, 0x40, 0x40, 0x40, 0x60, 0x3E, 0x06 ; C -> width 0 - 6
    db 0x7C, 0x42, 0x42, 0x42, 0x42, 0x42, 0x7C, 0x05 ; D -> width 0 - 6
    db 0x7E, 0x40, 0x40, 0x7E, 0x40, 0x40, 0x7E, 0x06 ; E -> width 0 - 6


; functions

raw_drawBitmap: ; 8x8 (SKIPS 8TH BYTE)
    ; params:
    ; ds:si -> bitmap pointer
    ; di -> draw address
    ; bl -> 256bit color

    push es

    mov ax, Video_memory_segment
    mov es, ax

    mov cl, 7
    .read_byte:

        mov ch, 8
        mov al, [ds:si]
        .draw_bit:

            test al, 10000000b
            jz .skip_draw_bit

            mov byte [es:di], bl

            .skip_draw_bit:
            shr al, 1
            inc di

        fastloop ch, .draw_bit

    ; .next_byte:
    dec cl
    jz short .done

    add di, 312 ; account for the bit reads
    inc si

    jmp short .read_byte

    .done:

    pop es
    ret

raw_drawPixels:
    ; params:
    ; di -> draw address
    ; ax -> width (GROW RIGHT) ; 0 - 320
    ; bh -> height (GROW DOWN) ; 0 - 200
    ; bl -> 256bit color

    push es

    mov dx, Video_memory_segment
    mov es, dx

    .draw_row:

        .draw_column:

            mov byte [es:di], bl
            inc di

        fastloop ax, .draw_column

        add di, 320
        sub di, ax

    fastloop bh, .draw_row

    pop es
    ret

raw_setBackground: ; bl (256bit color)

    push es
    
    mov ax, Video_memory_segment
    mov es, ax
    xor di, di ; 0x0000
    
    mov [background_color], bl
    mov bh, bl

    mov cx, 64000
    .fill:

        mov word [es:di], bx
        add di, 2

    fastloop cx, .fill

    pop es
    ret
