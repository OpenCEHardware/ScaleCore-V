cores := test_alu_ready_valid

define core/test_alu_ready_valid
  $(this)/deps := hsv_core_alu
  $(this)/targets := sim

  $(this)/rtl_top := test_alu_ready_valid

  $(this)/vl_main := test_alu_ready_valid.sv
endef

