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

# Build the kernel
$(KERNEL_IMAGE): $(KERNEL_DIR)/.config
	$(MAKE) -C $(KERNEL_DIR) oldconfig
	$(MAKE) -C $(KERNEL_DIR) -j$(nproc)

# Build the initramfs from the rootfs directory
$(INITRAMFS): $(ROOTFS_DIR)
	cd $(ROOTFS_DIR) && \
	find . -print0 | cpio --null -ov --format=newc | gzip -9 > ../$(INITRAMFS)

# Run QEMU with the kernel and initramfs
run: all
	qemu-system-x86_64 \
		-kernel $(KERNEL_IMAGE) \
		-initrd $(INITRAMFS) \
		-nographic \
		-append "console=ttyS0"

# Clean everything
clean:
	$(MAKE) -C $(KERNEL_DIR) mrproper
	rm -f $(INITRAMFS)

