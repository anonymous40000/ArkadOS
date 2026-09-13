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

gdt_end: ; метка конца

gdt_descriptor: ; размер таблицы и адрес начала 
    dw gdt_end - gdt_start - 1
    dd gdt_start

CODE_SEG equ gdt_code - gdt_start ;константы для селекторов сегментов кода и данных
DATA_SEG equ gdt_data - gdt_start
