# DIRECTORIES
BIN_DIR := ./bin
ISO_DIR := ./iso
KERNEL_DIR := ./LOS-Kernel
BOOTLOADER_DIR := ./LOS-Bootloader

# TARGET
ISO := $(BIN_DIR)/os.iso

# INTERMEDIATE
FAT := $(BIN_DIR)/fat.img

# SOURCE FILES
KERNEL := $(KERNEL_DIR)/bin/kernel.elf
BOOTLOADER := $(BOOTLOADER_DIR)/bin/BOOTX64.EFI

# PROGRAMS
EMULATOR := qemu-system-x86_64
EMULATOR_FLAGS := -bios OVMF.fd -cdrom $(ISO)
EMULATOR_DEBUG_FLAGS := -S -gdb tcp::1234 -d int

DEBUGGER := gdb
DEBUGGER_FLAGS := 

# BASE RULES
all: iso

iso: $(ISO)

run: $(ISO)
	@$(EMULATOR) $(EMULATOR_FLAGS)

run-debug: $(ISO)
	@$(EMULATOR) $(EMULATOR_FLAGS) $(EMULATOR_DEBUG_FLAGS) &
	@$(DEBUGGER) $(DEBUGGER_FLAGS)

clean:
	@rm -rf $(BIN_DIR)/*
	@rm -rf $(ISO_DIR)/*
	@make -C $(KERNEL_DIR) clean
	@make -C $(BOOTLOADER_DIR) clean

$(ISO): $(FAT) 
	@cp $(FAT) $(ISO_DIR)/fat.img
	@xorriso -as mkisofs -R -f -e fat.img -no-emul-boot -quiet -o $@ $(ISO_DIR)

$(FAT): dirs $(BOOTLOADER) $(KERNEL)
	@dd if=/dev/zero of=$@ bs=1k count=1440
	@mformat -i $@ -f 1440 ::
	@mmd -i $@ ::/EFI
	@mmd -i $@ ::/EFI/BOOT
	@mcopy -i $@ $(BOOTLOADER) ::/EFI/BOOT
	@mcopy -i $@ $(KERNEL) ::/

$(KERNEL):
	@make -C $(KERNEL_DIR)

$(BOOTLOADER):
	@make -C $(BOOTLOADER_DIR)

dirs:
	@mkdir -p $(BIN_DIR)
	@mkdir -p $(ISO_DIR)

.PHONY: dirs $(KERNEL) $(BOOTLOADER)