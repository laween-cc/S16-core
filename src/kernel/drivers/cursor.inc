[bits 16]
; INCLUDE
; drivers/draw.nasm

; Notes for feature development:
; Always perserve data segment registers

; variables

current_pos: dw 0

previous_write_width: 
    db 0 ; width
    db 0 ; IGNORE! DO NOT USE! KEEP ZERO

; functions

raw_write:
    ; params:
    ; di -> padding ; if you dont want any make sure it IS zerod OUT
    ; si -> bitmap pointer
    ; bl -> 256bit color

    push es

    add di, [current_pos]
    add di, [previous_write_width]

    call raw_drawBitmap

    ; read width
    mov al, [si + 1]
    mov byte [previous_write_width], al

    pop es
    ret

    