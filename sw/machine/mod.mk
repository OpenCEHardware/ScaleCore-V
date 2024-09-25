cores := hsv_machine_sw

define core/hsv_machine_sw
  $(this)/deps := hsv_picolibc

  $(this)/cc_files := \
    init.c
endef
