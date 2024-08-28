cores := tb_hsv_core_alu

define core/tb_hsv_core_alu
  $(this)/deps := hsv_core_alu
  $(this)/targets := sim

  $(this)/rtl_top := tb_hsv_core_alu

  $(this)/vl_main := tb_hsv_core_alu.sv
endef

