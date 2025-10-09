override build := ../../build

$(build)/VBR.BIN: vbr.nasm
	@mkdir -p $(dir $@)
	nasm -f bin $< -o $@

