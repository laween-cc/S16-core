override build := ../../build

$(build)/S16.SYS: s16.nasm
	@mkdir -p $(dir $@)
	nasm -f bin $< -o $@
