module hsv_core_fifo #(
    int WIDTH = 1,
    int DEPTH = 1
) (
    input logic clk_core,
    input logic rst_core_n,

    input logic flush,

    output logic               ready_o,
    input  logic               valid_i,
    input  logic [WIDTH - 1:0] in,

    input  logic               ready_i,
    output logic               valid_o,
    output logic [WIDTH - 1:0] out
);

  hsv_core_fifo_peek #(
      .WIDTH(WIDTH),
      .DEPTH(DEPTH)
  ) fifo (
      .clk_core,
      .rst_core_n,

      .flush,

      .ready_o,
      .valid_i,
      .in,

      .ready_i,
      .valid_o,
      .out,

      .peek_valid(),
      .peek_window()
  );

endmodule
