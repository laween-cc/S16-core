override build := build

$(build)/img/S16-core-floppy.img: $(build)/vbr.bin $(build)/io.sys $(build)/boot.syt
	@mkdir -p $(dir $@)
# write the floppy with zeros
	dd if=/dev/zero of=$@ bs=512 count=2880 conv=notrunc
	@sync
# format to fat12
	mkfs.fat -F 12 $@
	@sync
# inject volume boot record code into sector 0 (preserve JMP instruction, OEM name, BPB, extended BPB and volume name)
	dd if=$(build)/vbr.bin of=$@ bs=1 seek=62 count=448 conv=notrunc
	@sync
# copy IO.SYS into the fat12 partition
	mcopy -i $@ $(build)/io.sys ::IO.SYS
	mattrib -i $@ +R +H +S ::IO.SYS
# copy the BOOT.SYT into the fat12 partition
	mcopy -i $@ $(build)/boot.syt ::BOOT.SYT
	mattrib -i $@ +R +H +S ::BOOT.SYT

$(build)/vbr.bin: src/boot/vbr.nasm
	$(MAKE) -C src/boot/

$(build)/io.sys: src/io/io.nasm
	$(MAKE) -C src/io/

$(build)/boot.syt: src/boot.syt
	cp $< $@

.PHONY: clean

clean: $(build)
	rm -r $</* --preserve-root --verbose --one-file-system

qemu: $(build)/img/S16-core-floppy.img
	qemu-system-i386 -drive file=$<,format=raw,if=floppy -boot order=a