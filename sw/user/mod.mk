cores := hsv_user_sw

define core/hsv_user_sw
  $(this)/deps := hsv_picolibc

  $(this)/cc_files := \
    main.c
endef
