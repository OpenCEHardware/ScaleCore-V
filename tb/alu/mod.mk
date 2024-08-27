cores := tb_hsv_core_alu tb_hsv_core_masking tb_hsv_core_regfile

define core/tb_hsv_core_alu
  $(this)/deps := hsv_core_alu
  $(this)/targets := sim

  $(this)/rtl_top := tb_hsv_core_alu

  $(this)/vl_main := tb_hsv_core_alu.sv
endef

define core/tb_hsv_core_masking
  $(this)/deps := hsv_core_masking
  $(this)/targets := sim

  $(this)/rtl_top := tb_hsv_core_masking

  $(this)/vl_main := tb_hsv_core_masking.sv
endef

define core/tb_hsv_core_regfile
  $(this)/deps := hsv_core_regfile
  $(this)/targets := sim

  $(this)/rtl_top := tb_hsv_core_regfile

  $(this)/vl_main := tb_hsv_core_regfile.sv
endef

