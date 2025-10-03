override build := ../build

$(build)/IO.SYS: io.nasm
	@mkdir -p $(dir $@)
	nasm -f bin $< -o $@
