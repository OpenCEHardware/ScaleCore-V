top := hscale-v
core_dirs := rtl sim target

.PHONY: all

all: test

include mk/top.mk
