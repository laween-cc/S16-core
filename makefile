override build := build

os_version := 0.0
target := $(build)/img/S16-$(os_version).img

$(target): $(build)/boot.bin $(build)/kernel.bin
	@mkdir -p $(dir $@)
# write floppy with zeros
	dd if=/dev/zero of=$@ bs=512 count=2880
	@sync
# write MBR to first sector
	dd if=$(build)/boot.bin of=$@ bs=512 seek=0 count=1 conv=notrunc
	@sync
# write the kernel
	dd if=$(build)/kernel.bin of=$@ bs=512 seek=1 count=1 conv=notrunc
	@sync

$(build)/boot.bin: src/mbr/boot.nasm
	@$(MAKE) -C src/mbr

$(build)/kernel.bin: src/kernel/kernel.nasm
	@$(MAKE) -C src/kernel

.PHONY: xxd clean qemu

xxd: $(target)
	@xxd $<

clean:
# DO NOT RUN WITH SUPER PERMISSIONS
	rm -r $(build)/* --preserve-root --verbose --one-file-system

qemu: $(target)
	@qemu-system-i386 -drive if=floppy,format=raw,file=$< -boot order=a