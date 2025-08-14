KERNEL_DIR := linux
ROOTFS_DIR := rootfs
INITRAMFS := initramfs.cpio.gz
KERNEL_IMAGE := $(KERNEL_DIR)/arch/x86/boot/bzImage

.PHONY: all kernel initramfs run clean

all: $(KERNEL_IMAGE) $(INITRAMFS)

# Use existing .config if it exists, otherwise run defconfig
$(KERNEL_DIR)/.config:
	@if [ -f "$(KERNEL_DIR)/.config" ]; then \
		echo "Using existing kernel config"; \
	else \
		echo "No .config found, running defconfig"; \
		$(MAKE) -C $(KERNEL_DIR) defconfig; \
	fi

debug-full: $(KERNEL_DIR)/.config
	@echo "Enabling FULL DEBUG mode..."
	@$(MAKE) -C $(KERNEL_DIR) olddefconfig
	@$(KERNEL_DIR)/scripts/config --file $(KERNEL_DIR)/.config \
		--enable DEBUG_KERNEL \
		--enable DEBUG_INFO \
		--enable DEBUG_INFO_DWARF4 \
		--enable DEBUG_FS \
		--enable DEBUG_BUGVERBOSE \
		--enable DYNAMIC_DEBUG \
		--enable DYNAMIC_DEBUG_CORE
	@echo "FULL DEBUG mode enabled."

# Lightweight debug mode: keep dynamic debug but no big symbols
debug-lite: $(KERNEL_DIR)/.config
	@echo "Enabling LIGHTWEIGHT DEBUG mode..."
	@$(KERNEL_DIR)/scripts/config --file $(KERNEL_DIR)/.config \
		--disable DEBUG_KERNEL \
		--disable DEBUG_INFO \
		--disable DEBUG_INFO_DWARF4 \
		--enable DEBUG_FS \
		--enable DEBUG_BUGVERBOSE \
		--enable DYNAMIC_DEBUG \
		--enable DYNAMIC_DEBUG_CORE
	@echo "LIGHTWEIGHT DEBUG mode enabled."

# Build the kernel
$(KERNEL_IMAGE): $(KERNEL_DIR)/.config
	$(MAKE) -C $(KERNEL_DIR) oldconfig
	$(MAKE) -C $(KERNEL_DIR) -j1

# Build the initramfs from the rootfs directory
$(INITRAMFS): $(ROOTFS_DIR)
	cd $(ROOTFS_DIR) && \
	find . -print0 | cpio --null -ov --format=newc | gzip -9 > ../$(INITRAMFS)

# Run QEMU with the kernel and initramfs
run: all
	qemu-system-x86_64 \
		-kernel $(KERNEL_IMAGE) \
		-initrd $(INITRAMFS) \
		-m 512M

# Clean everything
clean:
	$(MAKE) -C $(KERNEL_DIR) clean
	rm -f $(INITRAMFS)

