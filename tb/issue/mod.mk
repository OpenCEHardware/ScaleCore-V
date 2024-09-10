cores := tb_hsv_core_issue_hazardmask tb_hsv_core_issue_regfile tb_hsv_core_issue

define core/tb_hsv_core_issue_hazardmmask
  $(this)/deps := hsv_core_issue_hazardmmask
  $(this)/targets := sim

  $(this)/rtl_top := tb_hsv_core_issue_hazardmmask

  $(this)/vl_main := tb_hsv_core_issue_hazardmmask.sv
endef

define core/tb_hsv_core_issue_regfile
  $(this)/deps := hsv_core_issue_regfile
  $(this)/targets := sim

  $(this)/rtl_top := tb_hsv_core_issue_regfile

  $(this)/vl_main := tb_hsv_core_issue_regfile.sv
endef

define core/tb_hsv_core_issue
  $(this)/deps := hsv_core_issue
  $(this)/targets := sim

  $(this)/rtl_top := tb_hsv_core_issue

  $(this)/vl_main := tb_hsv_core_issue.sv
endef
