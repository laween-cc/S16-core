; INCLUDE
; MACROS

%define Video_memory_segment 0xA000
%define Video_memory_top 0xFA00

; colors (VGA)
%define BLACK 0x00 
%define BLUE 0x01
%define GREEN 0x02
%define TEAL 0x03
%define RED 0x04
%define PURPLE 0x05
%define ORANGE 0x06
%define GREY 0x07
%define DARK_GREY 0x08
%define LIGHT_BLUE 0x09
%define LIGHT_GREEN 0x0A
%define LIGHT_TEAL 0x0B
%define LIGHT_RED 0x0C
%define PINK 0x0D
%define YELLOW 0x0E
%define WHITE 0x0F

; macros

; Notes for feature development:
; Everything that starts with 'i' is inlined and doesn't rely on a function

%macro igetDrawAddress 2
    ; Inlined version of getDrawAddress
    ; Preprocesses the X & Y
    ; NO REGISTERS!
    ; 1: X ; 0 - 319
    ; 2: Y ; 0 - 199
    ; return: di (draw address)

    mov di, %2 * 320 + %1

%endmacro 