cores := hsv_core_alu

define core
  $(this)/deps := hsv_core_alu hsv_core_pkg

  $(this)/rtl_top := hsv_core
  $(this)/rtl_files := hsv_core.sv
endef

define core/hsv_core_alu
  $(this)/deps := hsv_core_pkg

  $(this)/rtl_top := hsv_core_alu
  $(this)/rtl_files := hsv_core_alu.sv
endef

define core/hsv_core_pkg
  $(this)/deps := if_common

  $(this)/rtl_files := hsv_core_pkg.sv
endef
