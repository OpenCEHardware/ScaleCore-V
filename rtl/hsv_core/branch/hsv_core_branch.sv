module hsv_core_branch
  import hsv_core_pkg::*;
(
    input logic clk_core,
    input logic rst_core_n,

    input  logic flush_req,
    output logic flush_ack,

    // Input Channel (sink) signals
    input  branch_data_t branch_data,
    output logic         ready_o,
    input  logic         valid_i,

    // Output channel (source) signals
    output commit_data_t commit_data,
    input  logic         ready_i,
    output logic         valid_o
);

  logic stall;
  assign stall = ~ready_o;

  logic         valid_cond_target;
  branch_data_t branch_data_cond_target;
  logic         taken;
  word          target;

  logic         valid_jump;
  commit_data_t out_jump;

  // First substage
  hsv_core_branch_cond_target sub_cond_target (
      .clk_core,

      .stall,
      .flush_req,

      .valid_i,
      .in_branch_data(branch_data),

      .valid_o(valid_cond_target),
      .out_branch_data(branch_data_cond_target),

      .out_taken (taken),
      .out_target(target)
  );

  // Second substage
  hsv_core_branch_jump sub_jump (
      .clk_core,

      .stall,
      .flush_req,

      .valid_i(valid_cond_target),
      .in_branch_data(branch_data_cond_target),
      .in_taken(taken),
      .in_target(target),

      .out(out_jump),
      .valid_o(valid_jump)
  );

  // Buffering pipe
  hs_skid_buffer #(
      .WIDTH($bits(commit_data))
  ) branch_2_commit (
      .clk_core,
      .rst_core_n,

      .flush(flush_req),

      .in(out_jump),
      .ready_o,
      .valid_i(valid_jump),

      .out(commit_data),
      .ready_i,
      .valid_o
  );

  always_ff @(posedge clk_core or negedge rst_core_n)
    if (~rst_core_n) flush_ack <= 0;
    else flush_ack <= flush_req;

endmodule
