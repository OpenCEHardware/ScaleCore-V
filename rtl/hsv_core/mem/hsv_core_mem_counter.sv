module hsv_core_mem_counter
  import hsv_core_pkg::*;
(
    input logic clk_core,
    input logic rst_core_n,

    input logic up,
    input logic down,
    input logic flush,

    output mem_counter value
);

  always_ff @(posedge clk_core or negedge rst_core_n)
    if (~rst_core_n) value <= '0;
    else begin
      // Preserve the value if both up & down (they cancel each other)

      if (up & ~down) value <= value + 1;
      else if (~up & down) value <= value - 1;

      if (flush) value <= '0;
    end

endmodule
