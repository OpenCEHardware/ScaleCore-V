cores := hsv_core_alu

define core/hsv_core_alu
  $(this)/deps := hsv_core_pkg

  $(this)/rtl_top := hsv_core_alu
  $(this)/rtl_files := \
    hsv_core_alu.sv \
    hsv_core_alu_bitwise_setup.sv \
    hsv_core_alu_shift_add.sv
endef
