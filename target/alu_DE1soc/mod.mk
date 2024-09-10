define core
  $(this)/deps := hsv_core_alu hs_utils hsv_core_issue hsv_core_commit

  $(this)/rtl_top := hsv_core_commit

  $(this)/altera_device := 5CSEMA5F31C6
  $(this)/altera_family := Cyclone V
endef