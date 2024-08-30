cores := hsv_core_mem

define core/hsv_core_mem
  $(this)/deps := hsv_core_pkg

  $(this)/rtl_top := hsv_core_mem
  $(this)/rtl_files := \
    hsv_core_mem.sv \
    hsv_core_mem_address.sv \
    hsv_core_mem_request.sv \
    hsv_core_mem_response.sv \
    hsv_core_mem_counter.sv
endef
