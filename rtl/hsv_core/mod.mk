cores := \
	hsv_core_pkg \
	hsv_core_alu \
	hsv_core_branch \
	hsv_core_mem \
	hsv_core_masking \
	hsv_core_regfile \
	hsv_core_issue \
	hsv_core_muxing

define core
  $(this)/deps := hsv_core_alu hsv_core_pkg 

  $(this)/rtl_top := hsv_core
  $(this)/rtl_files := hsv_core.sv
endef

define core/hsv_core_pkg
  $(this)/deps := if_common hs_utils

  $(this)/rtl_files := hsv_core_pkg.sv
endef

define core/hsv_core_alu
  $(this)/deps := hsv_core_pkg

  $(this)/rtl_top := hsv_core_alu
  $(this)/rtl_files := hsv_core_alu.sv
endef

define core/hsv_core_branch
  $(this)/deps := hsv_core_pkg

  $(this)/rtl_top := hsv_core_branch
  $(this)/rtl_files := hsv_core_branch.sv
endef

define core/hsv_core_mem
  $(this)/deps := hsv_core_pkg

  $(this)/rtl_top := hsv_core_mem
  $(this)/rtl_files := hsv_core_mem.sv
endef

define core/hsv_core_masking
  $(this)/deps := hsv_core_pkg

  $(this)/rtl_top := hsv_core_masking
  $(this)/rtl_files := hsv_core_masking.sv
endef

define core/hsv_core_regfile
  $(this)/deps := hsv_core_pkg

  $(this)/rtl_top := hsv_core_regfile
  $(this)/rtl_files := hsv_core_regfile.sv
endef

define core/hsv_core_muxing
  $(this)/deps := hsv_core_pkg

  $(this)/rtl_top := hsv_core_muxing
  $(this)/rtl_files := hsv_core_muxing.sv
endef

define core/hsv_core_issue
  $(this)/deps := hsv_core_pkg hsv_core_masking hsv_core_muxing hsv_core_regfile

  $(this)/rtl_top := hsv_core_issue
  $(this)/rtl_files := hsv_core_issue.sv
endef
