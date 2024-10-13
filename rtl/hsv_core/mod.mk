cores := hsv_core_top_flat hsv_core_pkg hsv_core_regfile
subdirs := fetch decode issue alu foo mem branch ctrlstatus commit

define core
  $(this)/deps := \
    hsv_core_pkg \
    hsv_core_fetch \
    hsv_core_decode \
    hsv_core_issue \
    hsv_core_alu \
    hsv_core_foo \
    hsv_core_mem \
    hsv_core_branch \
    hsv_core_ctrlstatus \
    hsv_core_commit \
    hsv_core_regfile

  $(this)/rtl_top := hsv_core_top
  $(this)/rtl_files := hsv_core_top.sv
endef

define core/hsv_core_pkg
  $(this)/deps := if_common hs_utils

  $(this)/rtl_files := hsv_core_pkg.sv
endef

define core/hsv_core_regfile
  $(this)/deps := hsv_core_pkg

  $(this)/rtl_files := hsv_core_regfile.sv
endef

define core/hsv_core_top_flat
  $(this)/deps := hsv_core

  $(this)/rtl_top   := hsv_core_top_flat
  $(this)/rtl_files := hsv_core_top_flat.sv

  $(this)/qsys_ip_file := hsv_core_hw.tcl
endef
