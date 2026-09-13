NASM    := nasm
QEMU    := qemu-system-x86_64
CARGO   := cargo
OBJCOPY := objcopy

# --- размеры разделов на диске (в 512-байтных секторах) ---
# ВАЖНО: стейдж1 читает ровно STAGE2_SECTORS секторов стейджа2, а стейдж2 —
# ровно KERNEL_SECTORS секторов ядра сразу после себя. Оба значения зашиты
# в асм через -D, единственный источник истины — тут.
# Пока всё завязано на одну дорожку диска (стейдж1 + STAGE2_SECTORS +
# KERNEL_SECTORS <= 18 секторов), т.к. используется простое CHS-чтение
# без пересечения головок/дорожек.
STAGE2_SECTORS := 6
KERNEL_SECTORS := 10

# --- ассемблерный загрузчик ---
STAGE1_BIN := boot/boot_stage_1.bin
STAGE2_BIN := boot/boot_stage_2.bin
IMAGE      := disk.img

NASM_DEFS := -D STAGE2_SECTORS=$(STAGE2_SECTORS) -D KERNEL_SECTORS=$(KERNEL_SECTORS)

# --- ядро на Rust ---
CARGO_TARGET  := x86_64-unknown-none
CARGO_PROFILE := release
KERNEL_ELF    := target/$(CARGO_TARGET)/$(CARGO_PROFILE)/ArkadOS
KERNEL_BIN    := kernel.bin
KERNEL_MAX_BYTES := $(shell echo $$(( $(KERNEL_SECTORS) * 512 )))

CARGO_FLAGS := --target $(CARGO_TARGET)
ifeq ($(CARGO_PROFILE),release)
CARGO_FLAGS += --release
endif

.PHONY: all run clean kernel check-deps-boot check-deps-kernel help

all: check-deps-boot check-deps-kernel $(IMAGE) ## собрать полный образ диска (загрузчик + ядро)

help: ## показать список целей
	@grep -E '^[a-zA-Z_-]+:.*## ' $(MAKEFILE_LIST) | sed 's/:.*## /\t/'

# нужны только для сборки asm-загрузчика и запуска в qemu
check-deps-boot: ## проверить что nasm/qemu установлены
	@command -v $(NASM) >/dev/null 2>&1 || { echo "нет nasm: sudo apt install nasm"; exit 1; }
	@command -v $(QEMU) >/dev/null 2>&1 || { echo "нет qemu: sudo apt install qemu-system-x86"; exit 1; }

# нужны только для сборки rust-ядра
check-deps-kernel: ## проверить что cargo/objcopy установлены
	@command -v $(CARGO) >/dev/null 2>&1 || { echo "нет cargo: поставь rust через https://rustup.rs"; exit 1; }
	@command -v $(OBJCOPY) >/dev/null 2>&1 || { echo "нет objcopy: sudo apt install binutils"; exit 1; }
	@if command -v rustup >/dev/null 2>&1; then \
		rustup target list --installed 2>/dev/null | grep -q $(CARGO_TARGET) || \
			echo "внимание: таргет $(CARGO_TARGET) не стоит, запусти: rustup target add $(CARGO_TARGET)"; \
	fi

$(STAGE1_BIN): boot/boot_stage_1.asm
	$(NASM) -f bin $(NASM_DEFS) boot/boot_stage_1.asm -o $@

$(STAGE2_BIN): boot/boot_stage_2.asm boot/protected_mode.asm boot/print.asm boot/gdt_table.asm boot/long_mode.asm
	$(NASM) -f bin $(NASM_DEFS) -I boot/ boot/boot_stage_2.asm -o $@

kernel: check-deps-kernel $(KERNEL_BIN) ## собрать ядро в плоский бинарник kernel.bin

$(KERNEL_ELF): src/main.rs Cargo.toml linker.ld
	$(CARGO) build $(CARGO_FLAGS)

$(KERNEL_BIN): $(KERNEL_ELF)
	$(OBJCOPY) -O binary $< $@
	@size=$$(stat -c%s $@ 2>/dev/null || stat -f%z $@); \
	if [ "$$size" -gt "$(KERNEL_MAX_BYTES)" ]; then \
		echo "ошибка: kernel.bin весит $$size байт, а бюджет — $(KERNEL_MAX_BYTES) (KERNEL_SECTORS=$(KERNEL_SECTORS))"; \
		echo "увеличь KERNEL_SECTORS в Makefile"; \
		exit 1; \
	fi; \
	truncate -s $(KERNEL_MAX_BYTES) $@

$(IMAGE): $(STAGE1_BIN) $(STAGE2_BIN) $(KERNEL_BIN)
	cat $(STAGE1_BIN) $(STAGE2_BIN) $(KERNEL_BIN) > $@

run: $(IMAGE) ## собрать и запустить в qemu
	$(QEMU) -drive format=raw,file=$(IMAGE),if=floppy

clean: ## снести все собранные артефакты
	rm -f $(STAGE1_BIN) $(STAGE2_BIN) $(IMAGE) $(KERNEL_BIN)
	@command -v $(CARGO) >/dev/null 2>&1 && $(CARGO) clean || true
