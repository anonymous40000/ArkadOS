[BITS 16] ; генерируем как 16 битный код
in al, 0x92
and al, 0xFE
or al, 0x02
out 0x92, al ; включаем линию а20

lgdt [gdt_descriptor] ; подключаем таблицу дескрипторов
mov eax, cr0
or eax, 1
mov cr0, eax ; мы переходим в протектед мод 

jmp CODE_SEG:protected_mode_start ; и вот тут прыгаем в протектед мод окончательно

protected_mode_start:

[BITS 32] ; теперь мы в 32 битном коде
mov ax, DATA_SEG
mov ds, ax
mov es, ax
mov fs, ax
mov gs, ax
mov ss, ax 
mov esp, 0x900000 ; настраиваем указатель стека