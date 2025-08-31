; [bits 16]
; INCLUDE

; Notes for feature development:
; Always perserve data segment registers

drawBitmap: ; 8x8 (SKIPS 8TH BYTE) 
    ; params:
    ; ds:si -> bitmap pointer
    ; di -> draw address
    ; bl -> 256bit color
    ; perserves: es
    ; uses: ax, cx
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

        sfastloop ch, .read_bit 

    ; .next_byte:
    
    add di, 312
    inc si

    sfastloop cl, .read_byte

    pop es
    ret

drawPixels:
    ; params:
    ; di -> draw address
    ; ax -> width (GROW RIGHT) ; 1 - 320 ; WARNING: IF 0 IT WILL CAUSE A OVERFLOW!
    ; bh -> height (GROW DOWN) ; 1 - 200 ; WARNING: IF 0 IT WILL CAUSE A OVERFLOW!!
    ; bl -> 256bit color
    ; perserves: es
    ; uses: dx

    push es

    mov dx, Video_memory_segment
    mov es, dx

    .draw_row:

        mov dx, ax
        .draw_column:

            mov byte [es:di], bl
            inc di

        sfastloop dx, .draw_column

        add di, 320
        sub di, ax

    sfastloop bh, .draw_row

    pop es
    ret

setBackground:  
    ; params: bx ; WORD ; 256bit color (example: 0x0404)
    ; perserves: es
    ; uses: ax, di, cx

    push es
    
    mov ax, Video_memory_segment
    mov es, ax
    xor di, di ; 0x0000
    
    mov word [background_color], bx

    mov cx, 64000
    .fill:

        mov word [es:di], bx
        add di, 2

    sfastloop cx, .fill

    pop es
    ret

getDrawAddress: ; Use igetDrawAddress if you are directly providing the X & Y (NASM will preprocess it)
    ; params:
    ; cx -> X ; 0 - 319 ; WORD
    ; di -> Y ; 0 - 199 ; BYTE
    ; uses: ax
    ; return: di (draw address)

    mov ax, di
    sal di, 8
    sal ax, 6
    add di, ax
    add di, cx

    ret