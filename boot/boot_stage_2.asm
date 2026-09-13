; систему было решено сделать 64 битной
; загрузчик не вместится в 512 байт поэтому
; разнес загрузчик на 2 стейджа, в этом будет переход в лонгмод (64 бит)
[BITS 16]
ORG 0x8000

%include "protected_mode.asm"

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
jmp $

no_long_mode:
    mov esi, msg_fail
    call print_start
    jmp $

%include "print.asm"            ; функция печати

msg_ok   db "OKAK ARKADOKAK!", 0
msg_fail db "PORA OBNOVIT COMPUTER!", 0

%include "gdt_table.asm"   