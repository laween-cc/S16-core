; INCLUDE
; MACROS

%define Video_memory_segment 0xA000

; characters
%define WHITE_SPACE font + 0x00
%define A font + 0x08
%define B font + 0x10
%define C font + 0x18
%define D font + 0x20
%define E font + 0x28
%define F font + 0x30
%define G font + 0x38
%define H font + 0x40
%define I font + 0x48
%define J font + 0x50
%define K font + 0x58
%define L font + 0x60
%define M font + 0x68
%define N font + 0x70
%define O font + 0x78
%define P font + 0x80
%define Q font + 0x88
%define R font + 0x90
%define S font + 0x98
%define T font + 0xA0
%define W font + 0xA8
%define V font + 0xB0
%define X font + 0xB8
%define Y font + 0xC0
%define Z font + 0xC8

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
    ; NO REGISTERS!
    ; 1: color

    mov bx, (%1 << 8) | %1 

    call raw_setBackground
%endmacro

%macro getDrawAddress 2
    ; NO REGISTERS!
    ; 1: X ; 0 - 319
    ; 2: Y ; 0 - 199
    ; return: di (address)

    mov di, %2 * 320 + %1

%endmacro

%macro drawPixels 5
    ; 1: X ; NO REGISTER
    ; 2: Y ; NO REGISTER
    ; 3: WIDTH
    ; 4: HEIGHT
    ; 5: 256bit color

    mov di, %2 * 320 + %1
    mov ax, %3
    mov bh, %4
    mov bl, %5

    call raw_drawPixels

%endmacro