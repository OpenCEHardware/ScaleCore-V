module hsv_core
  import hsv_core_pkg::*;
(
    input logic clk_core,
    input logic rst_core_n,

    axib_if.m imem,
    axil_if.m dmem,

    input logic irq_core
);

endmodule
