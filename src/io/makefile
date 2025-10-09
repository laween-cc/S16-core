override build := ../../build

$(build)/io.sys: io.nasm
	@mkdir -p $(dir $@)
	nasm -f bin $< -o $@
