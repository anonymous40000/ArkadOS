ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
BOOT := $(ROOT)/boot

NASM := nasm
QEMU := qemu-system-x86_64

STAGE1_BIN := $(BOOT)/boot_stage_1.bin
STAGE2_BIN := $(BOOT)/boot_stage_2.bin
IMAGE := $(BOOT)/disk.img

all: $(IMAGE)

$(STAGE1_BIN): $(BOOT)/boot_stage_1.asm
	$(NASM) -f bin $(BOOT)/boot_stage_1.asm -o $@

$(STAGE2_BIN): $(BOOT)/boot_stage_2.asm $(BOOT)/protected_mode.asm $(BOOT)/print.asm $(BOOT)/gdt_table.asm
	$(NASM) -f bin $(BOOT)/boot_stage_2.asm -o $@ -I $(BOOT)

$(IMAGE): $(STAGE1_BIN) $(STAGE2_BIN)
	cat $(STAGE1_BIN) $(STAGE2_BIN) > $@

run: $(IMAGE)
	$(QEMU) -drive format=raw,file=$(IMAGE),if=floppy

clean:
	rm -f $(STAGE1_BIN) $(STAGE2_BIN) $(IMAGE)

.PHONY: all run clean
