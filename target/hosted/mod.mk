define core
  $(this)/targets := sim

  $(this)/deps := hsv_core_top_flat

  $(this)/rtl_top := hsv_core_top_flat

  $(this)/vl_main  := main.cpp
  $(this)/vl_files := axi.cpp elf_loader.cpp magic_io.cpp simulation.cpp
endef
