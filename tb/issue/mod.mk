cores := tb_hsv_core_masking tb_hsv_core_regfile tb_hsv_core_issue

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

define core/tb_hsv_core_issue
  $(this)/deps := hsv_core_issue
  $(this)/targets := sim

  $(this)/rtl_top := tb_hsv_core_issue

  $(this)/vl_main := tb_hsv_core_issue.sv
endef
