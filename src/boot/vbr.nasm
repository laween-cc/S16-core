[bits 16]
org 0x7C3E ; 0x7C00 + 62 (past the BPB)

; VBR is simple and dumb
; Just load IO.SYS to physical address 0x0000:0x0500 and hand control!

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

; precomputing to save bytes and cycles in the VBR (btw the OS will not use these)
%define precompute_root_start 0x6000
%define precompute_first_data 0x6001
%define precompute_log2_bytes_per_sector 0x6002 

start: ; bios SHOULD have loaded the boot drive in dl
    cli

    ; ===== set up registers =====
    xor cx, cx
    mov ds, cx
    mov es, cx

    mov ss, cx
    mov sp, 0x7C00

    ; sti ; whats the point in enabling hardware interrupts during this stage? Other than having stack over flows
    
    ; ===== read first sector of root =====
    ; reserved_logical_sectors + (2 * logical_sectors_per_fat)
    mov al, [0x7C00 + 0x00E]
    mov cl, [0x7C00 + 0x016]
    sal cl, 1
    add cl, al
    ; xor ch, ch
    mov byte [precompute_root_start], cl

    mov dh, 1 
    mov bx, 0x7E00 ; above the VBR
    call read_disk

enforce:
    ; ---- enforce < 16 entries in root ----
    mov cl, 16
    .enforce_16_entries:
   
    cmp byte [bx], 0x00 ; no more entries marker
    je .valid_amount_of_entries
    
    add bx, 32
    loop cl, .enforce_16_entries
    jmp error_screen
    .valid_amount_of_entries:
    
    ; ---- enforce system to have at LEAST have 128KiB of usable memory ----
    int 0x12
    cmp ax, 128
    jl error_screen

    ; ...

sys:
    ; ===== locate IO.SYS =====
    mov bx, 0x7E00
    mov cl, 16
    .read_entry:
    
    cmp byte [bx], 0x00 ; no more entries marker
    je error_screen

    mov si, bx
    mov di, io_file_name
    mov cx, 11
    ; cld
    repe cmpsb ; using cmpsb to save bytes 
    jnz .skip_entry

    ; IO.SYS found!
    mov si, bx ; switching registers
    
    ; ===== first data sector =====
    ; root_directory_sectors = (root_directory_entires * 32) / bytes_per_sector
    ; first_data_sector = [precompute_root_start] + root_directory_sectors
    mov ax, [0x7C00 + 0x011]
    sal ax, 5
    mov bx, [0x7C00 + 0x00B]
    xor cl, cl

    .log2_loop:
        sar bx, 1
        inc cl
        cmp bx, 1
        jne .log2_loop

    mov byte [precompute_log2_bytes_per_sector], cl    
    sar ax, cl

    mov cl, [precompute_root_start]
    add cl, al
    mov byte [precompute_first_data], cl
    ; xor ch, ch ; already zerod out

    ; ===== read first cluster to 0x0000:0x0500 =====
    ; (n - 2) * logical_sectors_per_cluster + first_data_sector
    mov ax, [si + 26]
    sub ax, 2
    mov dh, [0x7C00 + 0x00D]
    mul dh
    add cx, ax
    mov bx, 0x0500
    call read_disk

    ; ===== attempt follow fat chain ONCE =====
    ; if no cluster then skip to performing near jump
    ; if cluster then load at 0x0000:0x0700
    ; offset = N + (N / 2)
    ; sector_to_read = reserved_logical_sectors + (offset / bytes_per_sector)
    ; offset_in_sector_to_read = offset & bytes_per_sector - 1
    mov ax, [si + 26]
    mov bx, [si + 26]
    sar bx, 1
    add ax, bx ; offset
    push ax ; preserve

    mov cl, [precompute_log2_bytes_per_sector]
    sar ax, cl
    mov cx, [0x7C00 + 0x00E]
    add ax, cx ; sector to read

    mov cx, ax
    mov dh, 1
    mov bx, 0x8000
    call read_disk
    pop bx ; offset

    mov cx, [0x7C00 + 0x00B0]
    dec cx
    and bx, cx ; offset in sector to read
    add bx, 0x8000
    mov bx, [bx]

    test word [si + 26], 1
    jz .even

    ; ---- odd ----
    ; N >> 4
    shr bx, 4
    jmp .done_next_cluster
    ; ---- even ----
    ; N & 0x0FFF
    .even:
    and bx, 0x0FFF
    .done_next_cluster:
    cmp bx, 0x0FF8
    jge .jmp_io_sys ; assume 1KiB already loaded
    cmp bx, 0x0002
    jl error_screen ; assume corrupted fat12
    cmp bx, 0x0FEF
    jg error_screen ; assume corrupted fat12

    ; ===== read last cluster to 0x0000:0x0700 =====
    ; (N - 2) * logical_sectors_per_cluster + first_data_sector
    mov ax, bx
    sub ax, 2
    mov dh, [0x7C00 + 0x00D]
    mul dh
    mov cl, [precompute_first_data]
    xor ch, ch
    add cx, ax
    mov bx, 0x0700
    call read_disk

    .jmp_io_sys:
    jmp 0x0500 ; handle control to IO.SYS
    .skip_entry:
    add bx, 32
    loop cl, .read_entry

error_screen: ; tried to make this as small as possible (to save bytes) without having a trash error screen
    ; ---- clear screen ----
    xor ah, ah
    mov al, 0x03
    int 0x10

    ; ---- write error message to screen ----
    mov cl, 10
    mov si, error_message
    mov ah, 0x0E
    .write_byte:
        lodsb
        int 0x10
    loop cl, .write_byte

    ; ---- halt until key press & cold reboot ----
    sti ; enable hardware interrupts so we can get keyboard input again
    xor ah, ah
    int 0x16
    int 0x19

read_disk:
    ; dl -> boot drive
    ; dh -> number of sectors to read
    ; cx -> starting logical sector 
    ; es:bx -> dump

    ; ===== LBS to CHS conversion =====

    push es ; gotta preserve these registers
    push dx ;
    push bx ;

    mov bp, cx ; preserve the starting logical sector
    mov ah, 0x08
    int 0x13

    inc dh ; we need number of heads to start from 1
    and cl, 00111111b ; zero out bits 7 - 6 cause we need ONLY the sectors per track

    ; ---- cylinder ----
    ; LBS / (HPC * SPT)
    mov al, dh
    xor ah, ah
    mul cl

    mov bx, ax
    mov ax, bp
    xor dx, dx
    div bx
    mov bx, ax

    ; ---- head ----
    ; LBS % (HPC * SPT) / SPT
    mov ax, dx
    div cl
    
    ; ---- sector ----
    ; LBS % (HPC * SPT) % SPT + 1
    inc ah

    mov cx, bx ; put cylinder in the right place

    shl cl, 6 ; shift higher cylinder bits (0 - 1) to MSB (7 - 6)
    ; and ah, 00111111b
    or cl, ah ; combine the bits

    pop bx
    pop dx
    pop es

    xchg dh, al ; switch registers

    ; ---- int 13,2h ----
    mov ah, 0x02
    int 0x13

    jc error_screen ; handling it directly to save bytes
    ret

; variables

io_file_name: db "IO      " ; length: 8
io_extension: db "SYS" ; length: 3
error_message: db "VBR ERROR?" ; length: 10

times 446 - ($ - $$) db 0 ; pad to 446 bytes