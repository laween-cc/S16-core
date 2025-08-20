; INCLUDE
; MACROS

; Notes for feature development:
; - Everything that starts with 'i' is inlined and doesn't rely on a function
; - Bitmaps should be 8x8 so uhh don't act like there 8x16 or 16x16

%macro isetCursorPos 2
    ; 1: X
    ; 2: Y

    mov word [current_cursor_pos], %1
    mov byte [current_cursor_pos + 2], %2

%endmacro

%macro isetXmin 1
    ; Set the minimum X offset
    ; 1: X

    mov word [min_x_offset], %1

%endmacro

%macro isetYmin 1
    ; Set the minimum Y offset
    ; 1: Y

    mov word [min_y_offset], %1

%endmacro

%macro iNewline 0
    ; starts a newline 
    ; cursor_y + 9 
    ; cursor_x = min_x_offset
    ; AX register will be changed (make sure to perserve before using! If needed..)

    ; reset X
    mov ax, [min_x_offset]
    mov word [current_cursor_pos], ax

    ; new line (Y)
    add byte [current_cursor_pos + 2], 9

%endmacro