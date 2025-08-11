; INCLUDE
; MACROS

%define Video_memory_segment 0xA000

; characters
%define WHITE_SPACE 0x00
%define A 0x08
%define B 0x10
%define C 0x18
%define D 0x20
%define E 0x28
%define F 0x30
%define G 0x38
%define H 0x40
%define I 0x48
%define J 0x50
%define K 0x58
%define L 0x60
%define M 0x68
%define N 0x70
%define O 0x78
%define P 0x80
%define Q 0x88
%define R 0x90
%define S 0x98
%define T 0xA0
%define W 0xA8
%define V 0xB0
%define X 0xB8
%define Y 0xC0
%define Z 0xC8

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

%macro setBackground 1
    ; 1: color

    mov bl, %1

    call raw_setBackground
%endmacro

%macro getDrawAddress 2
    ; 1: X 0 - 319
    ; 2: Y 0 - 199
    ; REGISTERS THAT WILL BE OVERWRITTEN:
    ; - ax,
    ; - dx
    ; return: di (ADDRESS)

    mov ax, 320
    mov dx, %2
    mul dx
    add ax, %1
    mov di, ax

%endmacro