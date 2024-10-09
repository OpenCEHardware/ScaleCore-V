cores := hsv_machine_sw

define core/hsv_machine_sw
  $(this)/deps := hsv_picolibc

  $(this)/cc_files := \
    entry_exit.S \
    exc_map.c \
    init.c \
    insn_map.c \
    trap.c \
    semihosting.c \
    tohost.c
endef
