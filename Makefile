top := hsv_core
core_dirs := rtl sim target

.PHONY: all

all: test

include mk/top.mk
