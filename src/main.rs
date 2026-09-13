#![no_std]
#![no_main]

use core::panic::PanicInfo;

#[panic_handler]
fn panic(_info: &PanicInfo) -> ! {
    loop {}
}

#[unsafe(no_mangle)]
pub extern "C" fn _start() -> ! {
    // пишем "ARKADOS" прямо в текстовый видеобуфер (0xb8000),
    // чтобы визуально убедиться что ядро реально запустилось.
    // 0x2f = белый текст на зелёном фоне
    let vga = 0xb8000 as *mut u16;
    let msg = b"ARKADOS KERNEL OKak";
    for (i, &byte) in msg.iter().enumerate() {
        unsafe {
            vga.add(i).write_volatile(0x2f00 | byte as u16);
        }
    }

    loop {}
}