override build := ../../build
override target := $(build)/boot.bin

$(target): boot.nasm
	@mkdir -p $(dir $@)
	nasm -f bin $< -o $@

.PHONY: xxd

xxd: $(target)
	@xxd $<