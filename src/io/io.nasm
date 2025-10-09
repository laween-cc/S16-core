[bits 16]
org 0x0500

; titles format:
; ===== major section in label =====
; ===== minor section in label =====

; macros
%macro loop 2
    ; the loop instruction is slow so I am going to redefine it
    ; 1: register to decrement
    ; 2: address to jump when not 0
    ; warning: prone to overflows if 0 or negative

    dec %1
    jnz %2

%endmacro

; IO.SYS 0x0000:0x0500 - 0x0000:0x0900

%define io_data_segment 0x0000
; 1KiB for stack
%define io_reserved_stack 0xD00
%define bpb_start 0xD00

; file descripter structure:
; - first cluster (2 bytes)
; - file size (3 bytes)
; - time stamp (4 bytes)
; - cache number slot (1 byte)
; - file pointer (3 bytes)
; - attributes (1 byte)
; - reserved (2 bytes)
; total: 16 bytes

start:
    cli

    ; ===== set up data segments and stack again =====
    xor ax, ax
    mov ds, ax
    mov es, ax

    mov ss, ax
    mov sp, io_reserved_stack

    ; sti ; not enabling hardware interrupts to be more safe with stack

    ; ===== copy the BPB from 0x0000:0x7C00 =====
    mov si, 0x7C00
    mov di, bpb_start
    mov cx, 61
    cld
    rep movsb

    ; ===== set up absolute disk services =====
    mov word [0x20 * 4], int20_handler
    mov word [0x20 * 4 + 2], 0x0000

    ; ===== set up fat12 services ======
    mov word [0x21 * 4], int21_handler
    mov word [0x21 * 4 + 2], 0x0000

    ; ===== open & read BOOT.SYT =====

    ; ===== load specified file in /SYSTEM =====


error:

    xor ah, ah
    mov al, 0x03
    int 0x10

    jmp $ ; save bytes

int20_handler: ; absolute disk services
    ; ah -> ....
    ; returns:
    ; CF = 1 = invalid service
    ; ... (service dependent)
    ; services:
    ; 0x25 = absolute disk read
    ; 0x26 = absolute disk write

    stc
    iret

int21_handler: ; fat12 services
    ; ah -> ...
    ; returns:
    ; CF = 1 = invalid service / error in service
    ; ... (service dependent)
    ; services:
    ; 0xE4 = open
    ; 0xA3 = close
    ; 0x53 = next cluster
    ; 0x5E = next entry
    ; 0x2A = read
    ; 0x7B = write
    ; 0x8A = global flush


    stc
    iret

; variables
