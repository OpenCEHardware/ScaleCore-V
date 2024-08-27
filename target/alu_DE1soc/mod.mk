define core
  $(this)/deps := hsv_core_alu hs_utils hsv_core_masking hsv_core_regfile

  $(this)/rtl_top := hsv_core_regfile

  $(this)/altera_device := 5CSEMA5F31C6
  $(this)/altera_family := Cyclone V
endef