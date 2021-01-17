# DIRECTORIES
BIN_DIR := ./bin
ISO_DIR := ./iso
KERNEL_DIR := ./LOS-Kernel

# TARGET
ISO := $(BIN_DIR)/os.iso

# SOURCE FILES
KERNEL := $(KERNEL_DIR)/bin/kernel.elf

# PROGRAMS
EMULATOR := qemu-system-x86_64
EMULATOR_FLAGS := -boot d -cdrom $(ISO) -m 1024
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
	@rm -rf $(ISO_DIR)/kernel.elf
	@make -C $(KERNEL_DIR) clean

$(ISO): dirs $(KERNEL)
	@cp $(KERNEL) $(ISO_DIR)/kernel.elf
	@grub-mkrescue -o $@ $(ISO_DIR)

$(KERNEL):
	@make -C $(KERNEL_DIR)

dirs:
	@mkdir -p $(BIN_DIR)
	@mkdir -p $(ISO_DIR)

.PHONY: dirs $(KERNEL)