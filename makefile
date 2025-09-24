override build := build

os_version := 0.0

$(build)/img/S16-$(os_version)-floppy.img: $(build)/vbr.bin $(build)/IO.SYS
	@mkdir -p $(dir $@)
# write the floppy with zeros
	dd if=/dev/zero of=$@ bs=512 count=2880 conv=notrunc
	@sync
# format to fat12
	mkfs.fat -F 12 -n S16DISK $@
	@sync
# inject volume boot record code into sector 0 (preserve JMP instruction, OEM name, BPB, extended BPB and volume name)
	dd if=$(build)/vbr.bin of=$@ bs=1 seek=62 count=448 conv=notrunc
	@sync
# copy the kernel into the fat12 partiton
	mcopy -i $@ $(build)/IO.SYS ::IO.SYS
	mattrib -i $@ +R +H +S ::IO.SYS


$(build)/vbr.bin: src/boot/vbr.nasm
	$(MAKE) -C src/boot/

$(build)/IO.SYS: src/system/io.nasm
	$(MAKE) -C src/system/

.PHONY: clean

clean: $(build)
	rm -r $</* --preserve-root --verbose --one-file-system

qemu: $(build)/img/S16-$(os_version)-floppy.img
	qemu-system-i386 -drive file=$<,format=raw,if=floppy -boot order=a