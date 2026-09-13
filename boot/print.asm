print_start:
    mov edi, 0xB8000
    mov bh, 0x0F

print_loop:
    lodsb             
    
    test al, al        
    jz print_done      ; проверяем конец строки и выходим если да
    
    mov [edi], al      ; записываем символ в видеопамять
    mov [edi+1], bh    ; записываем цвет рядом
    add edi, 2         ; переходим к следующей позиции
    
    jmp print_loop     ; повторяем цикл

print_done:
    ret