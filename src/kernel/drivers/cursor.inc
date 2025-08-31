; [bits 16]
; INCLUDE
; draw.inc

; Notes for feature development:
; Always perserve data segment registers

write:
    ; al -> ACSII
    ; bl -> 256bit color (NO DEFAULTS!!)
    ; uses: ax, si, di, dx, bh
    ; calls: newline, drawBitmap
    ; return: bl (low byte) (WIDTH)

    xor ah, ah
    sal ax, 3
    mov si, font
    add si, ax

    ; Get the draw address
    mov di, [current_cursor_pos + 2]
    mov dx, [current_cursor_pos + 2]
    sal di, 8 ; ax * 2^8
    sal dx, 6 ; ax * 2^6
    add di, dx
    add di, [current_cursor_pos]

    call drawBitmap

    mov bl, [si] ; return
    xor bh, bh
    add word [current_cursor_pos], bx

    cmp word [current_cursor_pos], 311
    jnge short .done

    ; new line
    call newline

    .done:
    ret

newline:
    ; uses: ax, si, di, cx
    ; perserves: ds, es

    cmp byte [current_cursor_pos + 2], 192 ; 8 * 24
    je .scroll_down
    
    ; newline
    mov word [current_cursor_pos], 0x0000
    add byte [current_cursor_pos + 2], 8
    ret

.scroll_down:

    push ds
    push es

    mov ax, Video_memory_segment

    mov ds, ax
    mov si, 320 * 8

    mov es, ax
    xor di, di

    mov cx, (Video_memory_top - 320 * 8) / 2
    .scroll:

        mov ax, [ds:si]
        mov word [es:di], ax
        add si, 2
        add di, 2

    sfastloop cx, .scroll

    mov di, Video_memory_top - 320 * 8
    mov cx, (320 * 8) / 2
    .clear_bottom:

        mov word [es:di], 0x0000
        add di, 2

    sfastloop cx, .clear_bottom

    pop es
    pop ds

    ; incase needed:
    ; Y / 320 (to get Y in memory)

    mov word [current_cursor_pos], 0x0000
    ret

; User only functions (exposed via IVT) 
setCursorPos:
    ; ax -> X
    ; dl -> Y

    mov word [current_cursor_pos], ax
    mov byte [current_cursor_pos + 2], dl
    ret
