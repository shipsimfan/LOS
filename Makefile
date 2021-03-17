# DIRECTORIES
BIN_DIR := ./bin
ISO_DIR := ./iso
KERNEL_DIR := ./kernel
BOOTLOADER_DIR := ./bootloader
SHELL_DIR := ./shell
LIBC_DIR := ./libc
SYSROOT_DIR := ./sysroot
PROGRAMS_DIR := ./programs

# TARGET
ISO := $(BIN_DIR)/os.iso

# INTERMEDIATE
FAT := $(BIN_DIR)/fat.img

# SOURCE FILES
KERNEL := $(KERNEL_DIR)/bin/kernel.elf
BOOTLOADER := $(BOOTLOADER_DIR)/bin/BOOTX64.EFI
LOS_SHELL := $(SHELL_DIR)/bin/shell.app
LIBC := $(SYSROOT_DIR)/usr/lib/libc.a

# PROGRAMS
EMULATOR := qemu-system-x86_64
EMULATOR_FLAGS := -bios OVMF.fd -hdd $(FAT)
EMULATOR_DEBUG_FLAGS := -S -gdb tcp::1234 -no-reboot

DEBUGGER := gdb
DEBUGGER_FLAGS := --symbols=$(KERNEL) --eval-command="target remote localhost:1234"

# BASE RULES
all: hdd

iso: $(ISO)

run: hdd
	$(EMULATOR) $(EMULATOR_FLAGS)

run-debug: hdd
	@$(EMULATOR) $(EMULATOR_FLAGS) $(EMULATOR_DEBUG_FLAGS) &
	@$(DEBUGGER) $(DEBUGGER_FLAGS)

clean:
	@rm -rf $(BIN_DIR)/*
	@rm -rf $(ISO_DIR)/*
	@make -C $(KERNEL_DIR) clean -s
	@make -C $(BOOTLOADER_DIR) clean -s
	@make -C $(SHELL_DIR) clean -s
	@make -C $(LIBC_DIR) clean -s
	@make -C $(PROGRAMS_DIR) clean -s

hdd: $(LIBC) $(FAT) $(LOS_SHELL) programs
	@mcopy -s -i $(FAT) $(SYSROOT_DIR)/* ::/

$(ISO): $(LIBC) $(FAT) $(LOS_SHELL)
	@echo "[ LOS ] Building $@ . . ."
	@cp $(FAT) $(ISO_DIR)/fat.img
	@cp -r $(SYSROOT_DIR)/* $(ISO_DIR)/
	@xorriso -as mkisofs -R -f -e fat.img -no-emul-boot -o $@ $(ISO_DIR) -quiet
	@echo "[ LOS ] $@ Complete!"

$(FAT): dirs $(BOOTLOADER) $(KERNEL)
	@echo "[ LOS ] Building $@ . . ."
	@dd if=/dev/zero of=$@ bs=1k count=65536 status=none
	@mformat -i $@ -F ::
	@mmd -i $@ ::/EFI
	@mmd -i $@ ::/EFI/BOOT
	@mcopy -i $@ $(BOOTLOADER) ::/EFI/BOOT
	@mcopy -i $@ $(KERNEL) ::/
	@echo "[ LOS ] $@ Complete!"

$(KERNEL):
	@make -C $(KERNEL_DIR) -s

$(BOOTLOADER):
	@make -C $(BOOTLOADER_DIR) -s

$(LOS_SHELL):
	@make -C $(SHELL_DIR) -s install

$(LIBC):
	@make -C $(LIBC_DIR) -s install

programs:
	@make -C $(PROGRAMS_DIR) -s install

dirs:
	@mkdir -p $(BIN_DIR)
	@mkdir -p $(ISO_DIR)
	@mkdir -p $(ISO_DIR)/los
	@mkdir -p $(SYSROOT_DIR)

.PHONY: dirs $(KERNEL) $(BOOTLOADER) $(LOS_SHELL) $(LIBC) programs