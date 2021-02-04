# DIRECTORIES
BIN_DIR := ./bin
ISO_DIR := ./iso
KERNEL_DIR := ./kernel
BOOTLOADER_DIR := ./bootloader
SHELL_DIR := ./shell

# TARGET
ISO := $(BIN_DIR)/os.iso

# INTERMEDIATE
FAT := $(BIN_DIR)/fat.img

# SOURCE FILES
KERNEL := $(KERNEL_DIR)/bin/kernel.elf
BOOTLOADER := $(BOOTLOADER_DIR)/bin/BOOTX64.EFI
LOS_SHELL := $(SHELL_DIR)/bin/shell.app

# PROGRAMS
EMULATOR := DISPLAY=$(shell cat /etc/resolv.conf | grep nameserver | awk '{print $2}'):0 qemu-system-x86_64
EMULATOR_FLAGS := -bios OVMF.fd -cdrom $(ISO)
EMULATOR_DEBUG_FLAGS := -S -gdb tcp::1234 -d int,cpu_reset -no-reboot

DEBUGGER := gdb
DEBUGGER_FLAGS := --symbols=$(KERNEL) --eval-command="target remote localhost:1234"

# BASE RULES
all: iso

iso: $(ISO)

run: $(ISO)
	$(EMULATOR) $(EMULATOR_FLAGS)

run-debug: $(ISO)
	$(EMULATOR) $(EMULATOR_FLAGS) $(EMULATOR_DEBUG_FLAGS) &
	@$(DEBUGGER) $(DEBUGGER_FLAGS)

clean:
	@rm -rf $(BIN_DIR)/*
	@rm -rf $(ISO_DIR)/*
	@make -C $(KERNEL_DIR) clean
	@make -C $(BOOTLOADER_DIR) clean
	@make -C $(SHELL_DIR) clean

$(ISO): $(FAT) $(LOS_SHELL)
	@cp $(FAT) $(ISO_DIR)/fat.img
	@cp $(LOS_SHELL) $(ISO_DIR)/los/shell.app
	@xorriso -as mkisofs -R -f -e fat.img -no-emul-boot -o $@ $(ISO_DIR)

$(FAT): dirs $(BOOTLOADER) $(KERNEL)
	@dd if=/dev/zero of=$@ bs=1k count=65536
	@mformat -i $@ -F ::
	@mmd -i $@ ::/EFI
	@mmd -i $@ ::/EFI/BOOT
	@mcopy -i $@ $(BOOTLOADER) ::/EFI/BOOT
	@mcopy -i $@ $(KERNEL) ::/

$(KERNEL):
	@make -C $(KERNEL_DIR)

$(BOOTLOADER):
	@make -C $(BOOTLOADER_DIR)

$(LOS_SHELL):
	@make -C $(SHELL_DIR)

dirs:
	@mkdir -p $(BIN_DIR)
	@mkdir -p $(ISO_DIR)
	@mkdir -p $(ISO_DIR)/los

.PHONY: dirs $(KERNEL) $(BOOTLOADER) $(LOS_SHELL)