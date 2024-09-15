module hsv_core
  import hsv_core_pkg::*;
#(
    parameter word HART_ID = 0
) (
    input logic clk_core,
    input logic rst_core_n,

    axib_if.m imem,
    axil_if.m dmem,

    input logic irq_core
);

endmodule
