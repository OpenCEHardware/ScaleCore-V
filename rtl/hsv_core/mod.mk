cores := hsv_core_pkg hsv_core_alu hsv_core_branch

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
