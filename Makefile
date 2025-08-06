KERNEL_DIR := linux
ROOTFS_DIR := rootfs
INITRAMFS := initramfs.cpio.gz
KERNEL_IMAGE := $(KERNEL_DIR)/arch/x86/boot/bzImage

.PHONY: all kernel initramfs run clean

all: $(KERNEL_IMAGE) $(INITRAMFS)

# Build the kernel
$(KERNEL_IMAGE):
	cd $(KERNEL_DIR) && make defconfig
	cd $(KERNEL_DIR) && make -j$(nproc)

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
	cd $(KERNEL_DIR) && make mrproper
	rm -f $(INITRAMFS)

