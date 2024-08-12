define core
  $(this)/deps := if_common

  $(this)/rtl_top := hsv_core
  $(this)/rtl_dirs := .
  $(this)/rtl_files := hsv_core_pkg.sv hsv_core_pkg.sv
endef
