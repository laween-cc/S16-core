override build := ../../build

$(build)/boot.bin: boot.nasm
	@mkdir -p $(dir $@)
	nasm -f bin $< -o $@

boot2: $(build)/boot2.bin
$(build)/boot2.bin: boot2.nasm
	@mkdir -p $(dir $@)
	nasm -f bin $< -o $@