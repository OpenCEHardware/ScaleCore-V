cores := hsv_core_issue

define core/hsv_core_issue
  $(this)/deps := hsv_core_pkg

  $(this)/rtl_top := hsv_core_issue
  $(this)/rtl_files := \
    hsv_core_issue.sv \
    hsv_core_issue_masking.sv \
    hsv_core_issue_muxing.sv \
    hsv_core_issue_regfile.sv
endef
