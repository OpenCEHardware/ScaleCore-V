module hsv_core_alu
  import hsv_core_pkg::*;
(

    // Sequential signals
    input logic clk_core,
    input logic rst_core_n,

    // Flush signals
    input  logic flush_req,
    output logic flush_ack,

    // Input Channel (sink) signals
    input alu_data_t alu_data,
    output logic ready_o,
    input logic valid_i,

    // Output (source) signals
    output commit_data_t commit_data,
    input logic ready_i,
    output logic valid_o
);

  logic         stall;

  logic         valid_setup;
  alu_data_t    alu_data_setup;

  word          shift_lo;
  word          shift_hi;
  shift         shift_count;
  adder_in      adder_a;
  adder_in      adder_b;

  logic         valid_shift_add;
  commit_data_t out_shift_add;
  word          q_shift_add;

  // First Stage
  hsv_core_alu_bitwise_setup setup (
      .clk_core,

      .stall,
      .flush_req,

      .valid_i,
      .in_alu_data(alu_data),

      .valid_o(valid_setup),
      .out_alu_data(alu_data_setup),

      .out_shift_lo(shift_lo),
      .out_shift_hi(shift_hi),
      .out_shift_count(shift_count),
      .out_adder_a(adder_a),
      .out_adder_b(adder_b)
  );

  // Second Stage
  hsv_core_alu_shift_add shift_add (
      .clk_core,

      .stall,
      .flush_req,

      .valid_i(valid_setup),
      .in_alu_data(alu_data_setup),
      .in_shift_lo(shift_lo),
      .in_shift_hi(shift_hi),
      .in_shift_count(shift_count),
      .in_adder_a(adder_a),
      .in_adder_b(adder_b),

      .out(out_shift_add),
      .valid_o(valid_shift_add)
  );

  // Buffering pipe
  hs_skid_buffer #(
      .WIDTH($bits(commit_data))
  ) alu_2_commit (
      .clk_core,
      .rst_core_n,

      .stall,
      .flush_req,

      .in(out_shift_add),
      .ready_o,
      .valid_i(valid_shift_add),

      .out(commit_data),
      .ready_i,
      .valid_o
  );

  always_ff @(posedge clk_core or negedge rst_core_n) begin
    if (~rst_core_n) flush_ack <= 0;
    else flush_ack <= flush_req;
  end

endmodule
