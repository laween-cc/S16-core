[bits 16]
org 0x0500

; titles format:
; ===== major section in label =====
; ===== minor section in label =====

; macros
%macro loop 2
    ; the loop instruction is slow (and I want more control) so I am going to redefine it
    ; 1: register to decrement
    ; 2: address to jump when not 0
    ; warning: prone to overflows if 0 or negative

    dec %1
    jnz %2

%endmacro

; IO.SYS 0x0000:0x0500 - 0x0000:0x0900

%define io_data_segment 0x0000

%define io_reserved_stack 0x0D00 ; 1KiB (from high memory - low memory)
%define bpb_start 0x0D00 ; 61 bytes
%define boot_drive 0x0D3D ; 1 byte
%define root_start 0x0D3E ; 1 byte
%define root_sectors 0x0D3F ; 1 byte
%define first_data_sector 0x0D40 ; 1 byte
%define current_directory_cluster 0x0D41 ; 2 bytes
%define free_file_descripter_number 0x0D43 ; 1 byte
%define file_content_cache_bitmap 0x0D44 ; 10 bytes

%define io_cache_segment 0x00D4

%define root_cache 0x000E ; 16KiB
%define fat_n1_cache 0x400E ; 6KiB
%define file_content_cache 0x580E ; 40KiB

%define free_memory_segment 0x0F80
%define free_memory_offset 0x000E

; current directory cluster:
; root = 0x0000
; sub directory = first cluster number

; file descripter structure:
; first cluster (2 bytes)
; file size (3 bytes)
; time stamp (4 bytes)
; cache number slot (1 byte)
; file pointer (3 bytes)
; attributes (1 byte)
; reserved (2 bytes)
; total: 16 bytes
; get file descripter by doing:
; N * 2^4 (shift) OR N * 16 (mul)

; content cache structure:
; size = 40KiB
; slots = 79
; data section size in slot = 512 bytes
; next slot size in slot = 1 byte
; structure of slot:
; next - 1 byte
; data - 512 bytes
; get next slot position:
; (N << 9) + N (shifts) OR N * 513 (mul)
; get data slot position:
; (N << 9) + N + 1 (shifts) OR N * 513 + 1 (mul)
; 
; next section in the slot will have the number of the next SLOT to read
; 0xFF = end of chain

; error messages should be full caps

; sector_offset     bpb_offset  size
; 0x00B 	        0x00 	    WORD 	Bytes per logical sector
; 0x00D 	        0x02 	    BYTE 	Logical sectors per cluster
; 0x00E 	        0x03 	    WORD 	Reserved logical sectors
; 0x010 	        0x05 	    BYTE 	Number of FATs
; 0x011 	        0x06 	    WORD 	Root directory entries
; 0x013 	        0x08 	    WORD 	Total logical sectors
; 0x015 	        0x0A 	    BYTE 	Media descriptor
; 0x016 	        0x0B 	    WORD 	Logical sectors per FAT 
; 0x018 	        0x0D 	    WORD 	Physical sectors per track (identical to DOS 3.0 BPB)
; 0x01A 	        0x0F 	    WORD 	Number of heads (identical to DOS 3.0 BPB)
; 0x024 	        0x19 	    BYTE 	Physical drive number  
%define bpb_bytes_per_logical_sector bpb_start + 0x000B
%define bpb_logical_sectors_per_cluster bpb_start + 0x000D
%define bpb_reserved_logical_sectors bpb_start + 0x000E
%define bpb_number_of_fats bpb_start + 0x0010
%define bpb_root_directory_entries bpb_start + 0x0011
%define bpb_total_logical_sectors bpb_start + 0x0013
%define bpb_media_descripter bpb_start + 0x0015
%define bpb_logical_sectors_per_fat bpb_start + 0x0016
%define bpb_physical_sectors_per_track bpb_start + 0x0018
%define bpb_number_of_heads bpb_start + 0x001A
%define bpb_physical_drive_number bpb_start + 0x0024

; warning: tuned to fat12 and may not work on larger fat16 / fat32

start:
    cli

    ; ===== set up data segments and stack again =====
    xor ax, ax
    mov ds, ax
    mov es, ax

    mov ss, ax
    mov sp, io_reserved_stack

    mov byte [boot_drive], dl ; store the boot drive

    ; sti ; not enabling hardware interrupts to be more safe with stack

    cld ; set direction flag

    ; ===== copy the BPB from 0x0000:0x7C00 =====
    mov si, 0x7C00
    mov di, bpb_start
    mov cx, 61
    rep movsb ; using rep movsb to save bytes

    ; ===== precomputing =====

    ; root start sector
    ; reserved_logical_sectors + (2 * logical_sectors_per_fat)
    mov dl, [bpb_reserved_logical_sectors]
    mov dh, [bpb_logical_sectors_per_fat]
    shl dh, 1
    add dl, dh
    mov byte [root_start], dl

    ; root sectors
    ; (root_directory_entries * 32) / bytes_per_logical_sector
    mov ax, [bpb_root_directory_entries]
    shl ax, 5
    mov bx, [bpb_bytes_per_logical_sector]
    xor cl, cl

    .log2_loop:
    shr bx, 1
    inc cl
    cmp bx, 1
    jne .log2_loop

    shr ax, cl
    mov byte [root_sectors], al 

    ; first_data_sector
    ; root_start + root_sectors
    add dl, al
    mov byte [first_data_sector], dl

    ; ===== set current_directory_cluster, free_file_descripter_number, and file_content_cache_bitmap to 0 =====
    mov word [current_directory_cluster], 0
    mov byte [free_file_descripter_number], 0

    mov di, file_content_cache_bitmap
    xor al, al
    mov cx, 10
    rep stosb

    ; ===== set up absolute disk services =====
    mov word [0x25 * 4], absolute_read_disk
    mov word [0x25 * 4 + 2], 0x0000
    mov word [0x26 * 4], absolute_write_disk
    mov word [0x26 * 4 + 2], 0x0000

bootcfg:
    ; ===== open & read BOOT.CFG =====

    jmp $

kernel:
    ; ===== load specified file in /SYSTEM =====


error:
    ; si -> error message

    ; ---- clear the screen ----
    mov ax, 0x0003
    int 0x10

    mov ah, 0x0E
    ; ---- write the error message ----
    call .write        

    ; ---- reboot message ----
    mov si, error_reboot_help
    call .write

    ; ---- wait for key press and then cold reboot ----
    sti
    xor ah, ah
    int 0x16
    int 0x19

    .write:
    lodsb
    cmp al, 0
    je .write_end
    int 0x10 
    jmp .write
    .write_end:
    ret


absolute_read_disk: ; int 25h
    ; dl -> boot drive
    ; dh -> logical sectors to read (1 - 128)
    ; cx -> logical starting sector (can only address up to 8GB)
    ; es:bx -> dump address
    ; return:
    ; CF = 0 = success
    ; CF = 1 = failure
    ; ah = bios status

    push bx
    push dx
    push ax
    push bp
    push es

    ; ===== disable interrupts =====
    pushf ; so I can reset the interrupt flag back to its previous state
    cli

    ; ===== fix 64KiB segment boundary =====
    ; segment = current_segment + (current_offset << 4)
    ; offset = current_offset & 0x000F
    mov ax, bx
    shr ax, 4
    mov bp, es
    add ax, bp
    mov es, ax
    and bx, 0x000F

    ; ===== lbs to chs =====
    mov al, dh ; move logical sectors to read into al
    call lbs_to_chs

    jc .end ; failure? AH contains bios status

    ; ch = low cylinder
    ; cl = 7 - 6 bits = high cylinder
    ; cl = 0 - 5 bits = sector number
    ; dh = head

    ; ===== read the sectors from disk =====
    mov byte [.memory_scratch], al
    mov bp, 3 ; retry counter ; I ran out of registers..
    .bios_call:
    mov ah, 0x02
    int 0x13

    jnc .end ; success!

    ; ---- reset disk & retry ----
    dec bp
    jz .end ; failure! AH contains bios status and CF should still be set!

    xor ah, ah
    int 0x13

    jc .end ; failed to reset disk? AH contains bios status

    call wait_resync ; wait ~110ms to allow floppies / other storage devices to re-sync

    mov al, [.memory_scratch] ; restore sectors to read
    jmp .bios_call
    .end:

    ; ---- restore the interrupt status ----
    pop dx
    test dx, 0x100
    jz .interrupt_disabled
    sti
    .interrupt_disabled:

    ; ---- restore registers ----
    pop es
    pop bp
    pop dx ; ax
    mov al, dl ; restore al
    pop dx
    pop bx
    iret
    .memory_scratch: db 0

absolute_write_disk: ; int 26h

wait_resync:
    ; waits for ~110ms 
    ; I use this after a disk reset to ensure a floppy can re-sync
    ; relys on the IBM bios tick counter at 0x0040:0x006C.. otherwise will halt forever

    push es
    push bx

    mov bx, 0x0040
    mov es, bx
    mov bx, [es:0x00C6]
    add bx, 2 ; wait 2 ticks (~110ms)
    .wait_loop:
    cmp [es:0x00C6], bx
    jge .wait_loop

    pop bx
    pop es
    ret

lbs_to_chs:
    ; dl -> drive number
    ; cx -> logical starting sector
    ; returns:
    ; CF = 1 = failed to get drive parameters via int 13,8h?
    ; ah = bios status
    ; ch = low cylinder
    ; cl = 7 - 6 bits = high cylinder
    ; cl = 0 - 5 bits = sector number
    ; dh = head

    push es
    push di
    push bx
    push ax
    push dx
    push bp

    mov bp, cx ; preserve the LBS
    mov ah, 0x08
    int 0x13

    jc .end

    inc dh ; we need number of heads to start from 1
    and cl, 00111111b ; zero bits 7 - 6 (get rid of high cylinder bits) sense we only need the sectors per track

    ; ===== cylinder =====
    ; LBS / (HPC * SPT)
    mov al, dh
    xor ah, ah
    mul cl

    xchg bp, ax ; switch registers
    xor dx, dx
    div bp
    mov bp, ax

    ; ---- head ----
    ; LBS % (HPC * SPT ) / SPT
    mov ax, dx
    div cl

    ; ---- sector ----
    ; LBS % (HPC * SPT) % SPT + 1
    inc ah

    mov cx, bp ; put cylinder in the right place

    shl cl, 6 ; shift bits 0 - 1 to 7 - 6 and zero out bits 0 - 5
    ; and ah, 00111111b ; zero out bits 7 - 6
    or cl, ah ; combine the bits

    xor ah, ah ; no error
    clc
    .end:
    pop bp
    pop dx
    mov dh, al ; put head into the right place
    pop bx ; ax
    mov al, bl ; restore al
    pop bx
    pop di
    pop es
    ret

; variables

error_boot_syt: db "NO/INVALID BOOT.CFG", 0
error_disk: db "DISK ERROR", 0
error_reboot_help: db 0x0A, 0x0D ,"PRESS KEY TO REBOOT..", 0