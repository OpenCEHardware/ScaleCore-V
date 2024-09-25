top := hsv_core
core_dirs := rtl sw target tb

.PHONY: all

all: test

include mk/top.mk
