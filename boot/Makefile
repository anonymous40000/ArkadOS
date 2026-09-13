NASM := nasm
QEMU := qemu-system-x86_64

STAGE1_BIN := boot_stage_1.bin
STAGE2_BIN := boot_stage_2.bin
IMAGE := disk.img

all: $(IMAGE)

$(STAGE1_BIN): boot_stage_1.asm
	$(NASM) -f bin boot_stage_1.asm -o $@

$(STAGE2_BIN): boot_stage_2.asm protected_mode.asm print.asm gdt_table.asm
	$(NASM) -f bin boot_stage_2.asm -o $@

$(IMAGE): $(STAGE1_BIN) $(STAGE2_BIN)
	cat $(STAGE1_BIN) $(STAGE2_BIN) > $@

run: $(IMAGE)
	$(QEMU) -drive format=raw,file=$(IMAGE),if=floppy

clean:
	rm -f $(STAGE1_BIN) $(STAGE2_BIN) $(IMAGE)

.PHONY: all run clean
