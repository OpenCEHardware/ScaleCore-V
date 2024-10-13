define core
  $(this)/rtl_top   := cpu_inst
  $(this)/rtl_files := cpu_inst.v

  $(this)/altera_device := 5CSEMA5F31C6
  $(this)/altera_family := Cyclone V

  $(this)/sdc_files     := timing.sdc
  $(this)/qsf_files     := pins.tcl
  $(this)/qsys_deps     := hsv_core_top_flat
  $(this)/qsys_platform := cpu.qsys
endef
