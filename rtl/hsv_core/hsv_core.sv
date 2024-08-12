module hsv_core
import hsv_core_pkg::*;
(
	input  logic clk_core,
	             rst_core_n,

	if_axil.m    imem,
	if_axib.m    dmem,

	input  logic irq_core
);

endmodule
