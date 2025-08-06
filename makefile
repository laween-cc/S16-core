override build := build

os_version := 0.0
target := $(build)/img/S16-$(os_version).img

$(target): $(build)/boot.bin $(build)/kernel.bin $(build)/boot2.bin
	@mkdir -p $(dir $@)
# write floppy with zeros
	dd if=/dev/zero of=$@ bs=512 count=2880
	@sync
# write MBR to first sector (first stage)
	dd if=$(build)/boot.bin of=$@ bs=512 seek=0 count=1 conv=notrunc
	@sync
# write the second stage
	dd if=$(build)/boot2.bin of=$@ bs=512 seek=1 count=1 conv=notrunc
	@sync
# write the kernel
	dd if=$(build)/kernel.bin of=$@ bs=512 seek=2 count=2 conv=notrunc
	@sync

$(build)/boot.bin: src/bootloader/boot.nasm
	@$(MAKE) -C src/bootloader

$(build)/boot2.bin: src/bootloader/boot2.nasm
	@$(MAKE) -C src/bootloader boot2

$(build)/kernel.bin: src/kernel/kernel.nasm
	@$(MAKE) -C src/kernel

.PHONY: ghex clean qemu

ghex: $(target)
	@ghex $<

clean:
# DO NOT RUN WITH SUPER PERMISSIONS
	rm -r $(build)/* --preserve-root --verbose --one-file-system

qemu: $(target)
	@qemu-system-i386 -drive if=floppy,format=raw,file=$< -boot order=a