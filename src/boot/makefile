override build := ../../build

$(build)/vbr.bin: vbr.nasm
	@mkdir -p $(dir $@)
	nasm -f bin $< -o $@

