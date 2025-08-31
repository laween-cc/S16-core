[bits 16]
org 0x0000

; macros

%macro error 0

    ; push es

    mov ax, 0xA000 
    mov es, ax
    xor di, di ; 0x0000
    mov cx, 64000
    mov ax, 0x0404 ; red (2 bytes)

    .draw:

        mov word [es:di], ax
        add di, 2

    dec cx
    jnz .draw

    ; pop es

%endmacro

%macro relocateKernel 0
    ; DS:SI (mem_source), ES:DI (mem_dist), CX (nbytes)

    ; push ds
    ; push es

    xor ax, ax ; 0x0000
    ; source
    mov ds, ax
    mov si, 0x8400

    ; dist
    mov es, ax
    mov di, 0x7C00

    mov cx, 0x400 ; 1024 WORDS (2048 bytes)

    ; shr cx, 1 ; divide cx by 2 (WORD)

    ; test cl, 00000001b
    ; jz .even
    ; mov al, [ds:si] ; copy one byte to make it even
    ; mov [es:di], al
    ; inc di
    ; inc si
    ; dec cx
    ; .even:

    .copy_word:

        mov word ax, [ds:si] ; source
        mov word [es:di], ax ; dist
        add di, 2
        add si, 2

    dec cx
    jnz .copy_word

    ; pop ds
    ; pop es

%endmacro

; SECOND STAGE

start:
    cli

    ; data segments
    mov ax, cs ; 0x0800
    mov ds, ax
    mov es, ax
    ; mov fs, ax
    ; mov gs, ax

    ; stack
    xor ax, ax ; 0x0000
    mov ss, ax
    mov sp, 0x8400

    sti

    ; read kernel into memory
    ; push es
    ; xor ax, ax ; 0x0000
    mov es, ax
    mov bx, 0x8400

    mov ah, 0x02

        ; params
        mov al, 4
        mov ch, 0
        mov cl, 3
        mov dh, 0
        ; mov dl, 0 (0 = floppy A) ; should be set by bios already

    int 0x13

    jnc .success1
    error
    hlt
    .success1:

    ; pop es

    ; copy kernel to 0x0000:0x7C00
    relocateKernel

    jmp 0x0000:0x7C00 ; perform far jump to the kernel