define core
  $(this)/targets := sim

  $(this)/deps := hsv_core

  $(this)/rtl_top   := hosted_top
  $(this)/rtl_files := hosted_top.sv

  $(this)/vl_main  := main.cpp
  $(this)/vl_files := axi.cpp elf_loader.cpp simulation.cpp
endef
