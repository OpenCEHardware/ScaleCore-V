cores := hsv_core_fetch

define core/hsv_core_fetch
  $(this)/deps := hsv_core_pkg

  $(this)/rtl_top := hsv_core_fetch
  $(this)/rtl_files := \
    hsv_core_fetch.sv
endef
