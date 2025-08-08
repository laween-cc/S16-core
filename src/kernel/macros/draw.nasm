; INCLUDE
; MACROS

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

; numbers
%define ZERO 0x00
%define ONE 0x08
%define TWO 0x10
%define THREE 0x18
%define FOUR 0x20
%define FIVE 0x28
%define SIX 0x30
%define SEVEN 0x38
%define EIGHT 0x40
%define NINE 0x48

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

%macro drawPixels 5
    ; 1: X ; 0 - 319
    ; 2: Y ; 0 - 199
    ; 3: width ; 1 - 320
    ; 4: height ; 1 - 200
    ; 5: color

    mov ax, %1
    mov dx, %2
    mov si, %3
    mov bl, %4
    mov bh, %5

    call raw_drawPixels
%endmacro

%macro setBackground 1
    ; 1: color

    mov al, %1

    call raw_setBackground
%endmacro

%macro drawChar 4
    ; 1: X ; 0 - 319
    ; 2: Y ; 0 - 199
    ; 3: CHAR
    ; 4: color

    mov ax, %1
    mov dx, %2
    mov bl, %3
    mov bh, %4
    mov si, characters 

    call raw_drawBitmap
%endmacro

%macro drawNumber 4
    ; 1: X ; 0 - 319
    ; 2: Y ; 0 - 199
    ; 3: NUMBER
    ; 4: color

    mov ax, %1
    mov dx, %2
    mov bl, %3
    mov bh, %4
    mov si, numbers

    call raw_drawBitmap
%endmacro

%macro drawSymbol 4
    ; 1: X ; 0 - 319
    ; 2: Y ; 0 - 199
    ; 3: SYMBOL
    ; 4: color

    mov ax, %1
    mov dx, %2
    mov bl, %3
    mov bh, %4
    mov si, symbols

    call raw_drawBitmap
%endmacro