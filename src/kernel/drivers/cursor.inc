[bits 16]
; INCLUDE
; draw.inc

; variables

current_cursor_pos:
    dw 0 ; X
    db 0 ; Y
    db 0 ; IGNORE! (make sure nothing changes this byte)

min_x_offset: dw 0
min_y_offset: db 0

previous_write_width: db 0

; functions

raw_write:
    ; ds:si -> bitmap
    ; bl -> 256bit color (NO DEFAULTS!!)

    ; Get the draw address
    mov cx, [current_cursor_pos]
    mov dx, [current_cursor_pos + 2]

    call getDrawAddress
    call drawBitmap

    mov al, [si]
    xor ah, ah
    mov byte [previous_write_width], al
    add word [current_cursor_pos], ax

    ret
