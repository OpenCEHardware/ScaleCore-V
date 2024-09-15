cores := tb_hsv_core_alu

define core/tb_hsv_core_alu
  $(this)/deps := hsv_core_alu_tb_top
  $(this)/targets := test

  $(this)/rtl_top := hsv_core_alu_tb_top

  $(this)/cocotb_paths := .
  $(this)/cocotb_modules := tb_hsv_core_alu

endef
