module hs_skid_buffer #(
    int WIDTH = 1
) (
    input logic clk_core,
    input logic rst_core_n,

    input logic flush,

    input  logic [WIDTH - 1:0] in,
    output logic               ready_o,
    input  logic               valid_i,

    output logic [WIDTH - 1:0] out,
    input  logic               ready_i,
    output logic               valid_o
);

  logic was_ready, was_valid;
  logic [WIDTH - 1:0] skid_buf;

  assign out = ready_o ? in : skid_buf;
  assign ready_o = was_ready | ~was_valid;
  assign valid_o = (valid_i | ~ready_o) & ~flush;

  always_ff @(posedge clk_core or negedge rst_core_n)
    if (~rst_core_n) begin
      was_ready <= 0;
      was_valid <= 0;
    end else begin
      was_ready <= ready_i;
      if (ready_o) was_valid <= valid_i;

      if (flush) begin
        was_ready <= 0;
        was_valid <= 0;
      end
    end

  always_ff @(posedge clk_core) if (ready_o) skid_buf <= in;

endmodule
