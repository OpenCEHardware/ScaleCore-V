cores := hsv_core_branch

define core/hsv_core_branch
  $(this)/deps := hsv_core_pkg

  $(this)/rtl_top := hsv_core_branch
  $(this)/rtl_files := \
    hsv_core_branch.sv \
    hsv_core_branch_cond_target.sv \
    hsv_core_branch_jump.sv
endef
