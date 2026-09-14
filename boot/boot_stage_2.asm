; систему было решено сделать 64 битной
; загрузчик не вместится в 512 байт поэтому
; разнес загрузчик на 2 стейджа, в этом будет переход в лонгмод (64 бит)
[BITS 16]
ORG 0x8000

; добавляем пейджинг
PML4 equ 0x1000
PDPT equ 0x2000
PD   equ 0x3000

%include "protected_mode.asm" ; переход в протектед мод

mov dword [PML4], PDPT | 3
mov dword [PML4 + 4], 0

mov dword [PDPT], PD | 3
mov dword [PDPT + 4], 0

; начинаем проверки на поддержку процессором 64битной системы, иначе - зависаем
; первый шаг проверки
mov eax, 0x80000000
cpuid
cmp eax, 0x80000001
jb no_long_mode

; второй шаг
mov eax, 0x80000001
cpuid
test edx, 1 << 29
jz no_long_mode

; цикл для страниц 
mov ebx, PD
mov ecx, 512 ; маппим 1 гб 
mov eax, 0x83

fill_pd_loop:
    mov [ebx], eax
    mov dword [ebx + 4], 0
    add ebx, 8
    add eax, 0x200000
    loop fill_pd_loop

; тут начинаем включать пейджинг
mov eax, cr4
or eax, 1 << 5
mov cr4, eax

mov eax, PML4
mov cr3, eax

mov ecx, 0xC0000080
rdmsr
or eax, 1 << 8
wrmsr

mov eax, cr0
or  eax, 1 << 31 
mov cr0, eax

; все успешно
jmp CODE64_SEG:long_mode_start 

no_long_mode:
    mov esi, msg_fail
    call print_start
    jmp $

%include "print.asm"            ; функция печати

[BITS 64]
long_mode_start:
    mov esi, msg_ok
    call print_start
    jmp $

msg_ok   db "OKAK ARKADOKAK!", 0
msg_fail db "PORA OBNOVIT COMPUTER!", 0

%include "gdt_table.asm"   