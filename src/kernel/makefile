override build := ../../build
override target := $(build)/kernel.bin

$(target): kernel.nasm
	@mkdir -p $(dir $@)
	nasm -f bin $< -o $@

.PHONY: xxd

xxd: $(target)
	@xxd $<
