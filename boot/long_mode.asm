; минимальный переход в long mode — ровно столько, сколько нужно чтобы
; безопасно прыгнуть в 64-битное ядро. без изысков: identity-map первых
; 4 МиБ страницами по 2 МиБ (не нужен третий уровень таблиц — PT)

PML4_ADDR equ 0x70000
PDPT_ADDR equ 0x71000
PD_ADDR   equ 0x72000

; обнуляем все три таблицы (по 4096 байт)
mov edi, PML4_ADDR
mov ecx, (4096*3)/4
xor eax, eax
rep stosd

; PML4[0] -> PDPT
mov edi, PML4_ADDR
mov eax, PDPT_ADDR
or eax, 0b11            ; present + writable
mov [edi], eax

; PDPT[0] -> PD
mov edi, PDPT_ADDR
mov eax, PD_ADDR
or eax, 0b11
mov [edi], eax

; PD[0] и PD[1] -> две страницы по 2 МиБ, физически 0x000000 и 0x200000
; (PS=1 в дескрипторе страницы значит "это огромная 2МиБ страница", а не
; указатель на таблицу PT ещё уровнем ниже)
mov edi, PD_ADDR
mov eax, 0x00000083     ; present + writable + PS, база 0x000000
mov [edi], eax
add eax, 0x200000
mov [edi+8], eax

; CR3 <- физический адрес PML4
mov eax, PML4_ADDR
mov cr3, eax

; включаем PAE (обязателен для long mode)
mov eax, cr4
or eax, 1 << 5
mov cr4, eax

; ставим бит LME (long mode enable) в EFER через MSR
mov ecx, 0xC0000080
rdmsr
or eax, 1 << 8
wrmsr

; включаем paging в CR0 — с этого момента CPU реально в long mode
; (compatibility submode, пока мы всё ещё выполняем 32-битный код сегмента CODE_SEG)
mov eax, cr0
or eax, 1 << 31
mov cr0, eax

; дальний прыжок в 64-битный кодовый сегмент — это переключает CPU
; из compatibility submode в полноценный 64-битный режим
jmp CODE64_SEG:long_mode_start

[BITS 64]
long_mode_start:
    mov ax, DATA_SEG
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov rsp, 0x200000    ; временный стек ядра, где-то в замапленных 4 МиБ

    jmp KERNEL_PHYS_ADDR ; прыгаем в _start ядра (слинковано на этот адрес)
