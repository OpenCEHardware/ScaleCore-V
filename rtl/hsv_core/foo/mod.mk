cores := hsv_core_foo

define core/hsv_core_foo
  $(this)/deps := hsv_core_pkg

  $(this)/rtl_top := hsv_core_foo
  $(this)/rtl_files := \
    hsv_core_foo.sv
endef
