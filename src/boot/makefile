override build := ../../build

$(build)/boot.bin: boot.nasm
	@mkdir -p $(dir $@)
	nasm -f bin $< -o $@

