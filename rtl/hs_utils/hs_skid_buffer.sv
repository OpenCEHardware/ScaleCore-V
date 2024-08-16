module hs_skid_buffer #(
    int WIDTH = 1
) (
    input logic clk_core,
    input logic rst_core_n,

    output logic stall,
    input  logic flush_req,

    input  logic [WIDTH - 1:0] in,
    output logic               in_ready,
    input  logic               in_valid,

    output logic [WIDTH - 1:0] out,
    input  logic               out_ready,
    output logic               out_valid
);

  logic was_ready, was_valid;
  logic [WIDTH - 1:0] skid_buf;

  assign out = stall ? skid_buf : in;
  assign stall = ~in_ready;
  assign in_ready = was_ready | ~was_valid;
  assign out_valid = in_valid | stall;

  always_ff @(posedge clk_core) begin
    was_ready <= out_ready;
    if (~stall) begin
      skid_buf  <= in;
      was_valid <= in_valid;
    end

    if (flush_req) begin
      was_ready <= 0;
      was_valid <= 0;
    end
  end

endmodule
