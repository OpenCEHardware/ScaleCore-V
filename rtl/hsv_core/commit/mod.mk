cores := hsv_core_commit

define core/hsv_core_commit
  $(this)/deps := hsv_core_pkg

  $(this)/rtl_top := hsv_core_commit
  $(this)/rtl_files := \
    hsv_core_commit.sv \
	
endef
