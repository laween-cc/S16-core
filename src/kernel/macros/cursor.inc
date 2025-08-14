; INCLUDE
; MACROS

%macro setCursorPos 1
    ; NO REGISTERS
    ; 1: X
    ; 2: Y

    mov word [current_pos], %2 * 320 + %1

%endmacro

%macro resetPreviousWriteWidth 0

    mov byte [previous_write_width], 0

%endmacro