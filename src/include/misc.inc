%ifndef MISC_INC
%define MISC_INC

%define boot_drive 0x053E
%define root_directory_logical_starting_sector 0x053F
%define root_directory_logical_sectors 0x0540
%define first_logical_data_sector 0x0541

%macro loop 2
    ; the loop instruction is slow so I am going to redefine it
    ; 1: register to decrement
    ; 2: address to jump when not 0
    ; warning: prone to overflows if 0 or negative

    dec %1
    jnz %2

%endmacro

%macro halt 0
    ; Hangs but allows interrupts

    sti
%%._hang_loop:
        hlt
        jmp %%._hang_loop

%endmacro

%endif