override build := ../../build
override target := $(build)/kernel.bin
override drivers := $(wildcard drivers/*)
override macros := $(wildcard macros/*)

$(target): kernel.nasm $(drivers) $(macros)
	@mkdir -p $(dir $@)
	nasm -f bin $< -o $@

.PHONY: xxd

xxd: $(target)
	@xxd $<
