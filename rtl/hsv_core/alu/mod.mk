cores := hsv_core_alu_tb_top

define core/hsv_core_alu_tb_top
  $(this)/deps := hsv_core_pkg

  $(this)/rtl_top := hsv_core_alu_tb_top
  $(this)/rtl_files := \
    hsv_core_alu_tb_top.sv \
    hsv_core_alu.sv \
    hsv_core_alu_bitwise_setup.sv \
    hsv_core_alu_shift_add.sv \
    hsv_core_alu_opcode.sv
endef
