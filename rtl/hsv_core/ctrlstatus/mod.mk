cores := hsv_core_ctrlstatus hsv_core_ctrlstatus_regs

define core/hsv_core_ctrlstatus
  $(this)/deps := hsv_core_pkg hsv_core_ctrlstatus_regs

  $(this)/rtl_top := hsv_core_ctrlstatus
  $(this)/rtl_files := \
    hsv_core_ctrlstatus.sv \
    hsv_core_ctrlstatus_counters.sv \
    hsv_core_ctrlstatus_global_fsm.sv \
    hsv_core_ctrlstatus_readwrite.sv
endef

define core/hsv_core_ctrlstatus_regs
  $(this)/hooks := regblock

  $(this)/regblock_rdl := hsv_core_ctrlstatus_regs.rdl
  $(this)/regblock_top := hsv_core_ctrlstatus_regs
  $(this)/regblock_args := --default-reset arst_n
  $(this)/regblock_cpuif := passthrough
endef
