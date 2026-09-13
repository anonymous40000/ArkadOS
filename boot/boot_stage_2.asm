; систему было решено сделать 64 битной
; загрузчик не вместится в 512 байт поэтому
; разнес загрузчик на 2 стейджа, в этом будет переход в лонгмод (64 бит)
[BITS 16]
ORG 0x8000

; размеры считаются в Makefile и приходят сюда через -D,
; чтобы не дублировать константы в двух местах
%ifndef STAGE2_SECTORS
%define STAGE2_SECTORS 6
%endif
%ifndef KERNEL_SECTORS
%define KERNEL_SECTORS 10
%endif

KERNEL_LOAD_SECTOR equ 2 + STAGE2_SECTORS ; ядро лежит сразу после стейджа2
KERNEL_TMP_SEG     equ 0x1000             ; временный буфер для чтения (линейно 0x10000)
KERNEL_PHYS_ADDR   equ 0x100000           ; куда копируем ядро в protected mode (1 МиБ)

; --- читаем ядро с диска, пока мы ещё в реал моде (BIOS доступен только тут) ---
load_kernel:
    mov ax, KERNEL_TMP_SEG
    mov es, ax
    xor bx, bx

    mov ah, 0x02
    mov al, KERNEL_SECTORS
    mov ch, 0
    mov cl, KERNEL_LOAD_SECTOR
    mov dh, 0
    mov dl, 0
    int 0x13

    jc kernel_read_error
    jmp kernel_loaded

kernel_read_error:
    jmp $

kernel_loaded:

%include "protected_mode.asm"

; мы в 32-битном protected mode. переносим ядро из временного буфера
; (линейно 0x10000) туда, где его ждёт линкер ядра — 0x100000
mov esi, 0x10000
mov edi, KERNEL_PHYS_ADDR
mov ecx, (KERNEL_SECTORS * 512) / 4
rep movsd

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

; все успешно
mov esi, msg_ok
call print_start

%include "long_mode.asm"        ; paging + переход в long mode + прыжок в ядро

[BITS 32] ; long_mode.asm заканчивается в 64-битном режиме сборки, возвращаем 32,
          ; тк дальше идёт код, который реально исполняется ДО перехода в long mode

no_long_mode:
    mov esi, msg_fail
    call print_start
    jmp $

%include "print.asm"            ; функция печати

msg_ok   db "OKAK ARKADOKAK!", 0
msg_fail db "PORA OBNOVIT COMPUTER!", 0

%include "gdt_table.asm"

times (STAGE2_SECTORS*512)-($-$$) db 0
; если этот times ушёл в минус — стейдж2 вырос за пределы STAGE2_SECTORS,
; надо увеличить константу в Makefile
