cores := hsv_machine_sw

define core/hsv_machine_sw
  $(this)/deps := hsv_picolibc

  $(this)/cc_files := \
    csr_map.c \
    entry_exit.S \
    emulation.c \
    exc_map.c \
    init.c \
    insn_map.c \
    trap.c \
    semihosting.c \
    tohost.c
endef
