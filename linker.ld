/* линкер-скрипт для ядра ArkadOS */
/* грузим ядро с классического адреса 1 МиБ — стандарт для x86 кернелов */

ENTRY(_start)

SECTIONS
{
    . = 0x100000;

    .text :
    {
        *(.text .text.*)
    }

    .rodata :
    {
        *(.rodata .rodata.*)
    }

    .data :
    {
        *(.data .data.*)
    }

    .bss :
    {
        *(.bss .bss.*)
        *(COMMON)
    }

    /DISCARD/ :
    {
        *(.comment)
        *(.eh_frame)
        *(.note .note.*)
    }
}
