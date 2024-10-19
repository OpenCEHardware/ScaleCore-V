cores := hsv_core_utils

define core/hsv_core_utils
  $(this)/rtl_files := \
    hsv_core_fifo.sv \
    hsv_core_fifo_peek.sv \
    hsv_core_skid_buffer.sv
endef
