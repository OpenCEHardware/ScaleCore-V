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
  assign valid_o = valid_i | ~ready_o;

  always_ff @(posedge clk_core) begin
    was_ready <= ready_i;
    if (ready_o) begin
      skid_buf  <= in;
      was_valid <= valid_i;
    end

    if (flush) begin
      was_ready <= 0;
      was_valid <= 0;
    end
  end

endmodule
