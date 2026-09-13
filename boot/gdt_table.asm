gdt_start: ; метка начала

gdt_null: ; нулевой дескриптор обязательный для заполнения
    dd 0
    dd 0

gdt_code: ; дескриптор кода
    dw 0xFFFF
    dw 0x0000
    db 0x00
    db 0x9A
    db 0xCF
    db 0x00

gdt_data: ; дескриптор данных
    dw 0xFFFF
    dw 0x0000
    db 0x00
    db 0x92
    db 0xCF
    db 0x00

gdt_code64: ; дескриптор 64-битного кода (для long mode)
    dw 0x0000 ; limit игнорируется в long mode
    dw 0x0000 ; base low
    db 0x00   ; base mid
    db 0x9A   ; present, ring0, code, exec/read — как у обычного кода
    db 0x20   ; флаги: L=1 (это и есть маркер 64-битного сегмента)
    db 0x00   ; base high

gdt_end: ; метка конца

gdt_descriptor: ; размер таблицы и адрес начала 
    dw gdt_end - gdt_start - 1
    dd gdt_start

CODE_SEG equ gdt_code - gdt_start ;константы для селекторов сегментов кода и данных
DATA_SEG equ gdt_data - gdt_start
CODE64_SEG equ gdt_code64 - gdt_start
