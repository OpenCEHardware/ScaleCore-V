module hsv_core_issue
  import hsv_core_pkg::*;
(
    // Sequential signals
    input logic clk_core,
    input logic rst_core_n,

    // Flush signals
    input  logic flush_req,
    output logic flush_ack,

    // Input Channel (sink) signals
    input issue_data_t issue_data,
    output logic ready_o,
    input logic valid_i,

    // Output (source) signals
    output alu_data_t alu_data,
    output foo_data_t foo_data,
    output mem_data_t mem_data,
    output branch_data_t branch_data,
    output ctrlstatus_data_t ctrlstatus_data,

    input logic alu_ready_i,
    input logic foo_ready_i,
    input logic mem_ready_i,
    input logic branch_ready_i,
    input logic ctrlstatus_ready_i,

    output logic alu_valid_o,
    output logic foo_valid_o,
    output logic mem_valid_o,
    output logic branch_valid_o,
    output logic ctrlstatus_valid_o,

    // Regfile signals
    input reg_addr wr_addr,
    input word wr_data,
    input logic wr_en,

    // Commit feedback signals
    input reg_mask commit_mask
);

  // Regfile
  reg_addr rs1_addr;
  reg_addr rs2_addr;
  word rs1_data;
  word rs2_data;

  // Hazard hazard_mask unit
  reg_mask hazard_mask;
  reg_mask rd_mask;
  issue_data_t issue_data_hazard_mask;
  logic valid_hazard_mask;

  // Fork unit
  alu_data_t fork_alu_data;
  foo_data_t fork_foo_data;
  mem_data_t fork_mem_data;
  branch_data_t fork_branch_data;
  ctrlstatus_data_t fork_ctrlstatus_data;
  logic valid_alu_fork;
  logic valid_foo_fork;
  logic valid_mem_fork;
  logic valid_branch_fork;
  logic valid_ctrlstatus_fork;

  // Pipes and stalls
  // TODO: Check if we want so much freefloating logic in top modules
  logic alu_pipe_ready_i;
  logic foo_pipe_ready_i;
  logic mem_pipe_ready_i;
  logic branch_pipe_ready_i;
  logic ctrlstatus_pipe_ready_i;

  logic alu_stall;
  logic foo_stall;
  logic mem_stall;
  logic branch_stall;
  logic ctrlstatus_stall;

  assign alu_stall = ~alu_pipe_ready_i;
  assign foo_stall = ~foo_pipe_ready_i;
  assign mem_stall = ~mem_pipe_ready_i;
  assign branch_stall = ~branch_pipe_ready_i;
  assign ctrlstatus_stall = ~ctrlstatus_pipe_ready_i;

  logic stall;
  logic hazard;
  logic hazard_stall;
  logic exec_mem_stall;

  assign stall = hazard_stall | exec_mem_stall;
  assign hazard_stall = valid_hazard_mask & hazard;
  assign exec_mem_stall = alu_stall | mem_stall | foo_stall | branch_stall | ctrlstatus_stall;
  assign ready_o = ~stall;

  // Register File
  hsv_core_issue_regfile reg_file (
      .clk_core,
      .rst_n(rst_core_n),
      .rs1_addr,
      .rs2_addr,
      .wr_addr,
      .wr_data,
      .wr_en,
      .rs1_data,
      .rs2_data
  );

  // First stage: Hazard hazard_mask generation logic
  hsv_core_issue_hazardmask hazard_mask_stage (
      .clk_core,

      .stall,
      .flush_req,

      .issue_data,
      .valid_i,

      .mask(hazard_mask),
      .rd_mask,
      .out(issue_data_hazard_mask),
      .valid_o(valid_hazard_mask)
  );

  // Second stage: Pipeline forks into each of the execution ports
  hsv_core_issue_fork fork_stage (
      .clk_core,

      .stall,
      .alu_stall,
      .foo_stall,
      .mem_stall,
      .branch_stall,
      .ctrlstatus_stall,
      .exec_mem_stall,
      .flush_req,

      .issue_data(issue_data_hazard_mask),
      .mask(hazard_mask),
      .rd_mask,
      .commit_mask,
      .rs1_addr,
      .rs2_addr,
      .rs1_data,
      .rs2_data,
      .valid_i(valid_hazard_mask),

      .alu_valid_o(valid_alu_fork),
      .foo_valid_o(valid_foo_fork),
      .mem_valid_o(valid_mem_fork),
      .branch_valid_o(valid_branch_fork),
      .ctrlstatus_valid_o(valid_ctrlstatus_fork),

      .alu_data(fork_alu_data),
      .foo_data(fork_foo_data),
      .mem_data(fork_mem_data),
      .branch_data(fork_branch_data),
      .ctrlstatus_data(fork_ctrlstatus_data),

      .hazard
  );

  // Third stage: Buffering pipelines (one skid buffer per PU in exec-mem)
  // ALU
  hs_skid_buffer #(
      .WIDTH($bits(alu_data))
  ) issue_2_alu (
      .clk_core,
      .rst_core_n,

      .flush(flush_req),

      .in(fork_alu_data),
      .ready_o(alu_pipe_ready_i),
      .valid_i(valid_alu_fork),

      .out(alu_data),
      .ready_i(alu_ready_i),
      .valid_o(alu_valid_o)
  );

  // Foo
  hs_skid_buffer #(
      .WIDTH($bits(foo_data))
  ) issue_2_foo (
      .clk_core,
      .rst_core_n,

      .flush(flush_req),

      .in(fork_foo_data),
      .ready_o(foo_pipe_ready_i),
      .valid_i(valid_foo_fork),

      .out(foo_data),
      .ready_i(foo_ready_i),
      .valid_o(foo_valid_o)
  );

  // Memory
  hs_skid_buffer #(
      .WIDTH($bits(mem_data))
  ) issue_2_memory (
      .clk_core,
      .rst_core_n,

      .flush(flush_req),

      .in(fork_mem_data),
      .ready_o(mem_pipe_ready_i),
      .valid_i(valid_mem_fork),

      .out(mem_data),
      .ready_i(mem_ready_i),
      .valid_o(mem_valid_o)
  );

  // Branch
  hs_skid_buffer #(
      .WIDTH($bits(branch_data))
  ) issue_2_branch (
      .clk_core,
      .rst_core_n,

      .flush(flush_req),

      .in(fork_branch_data),
      .ready_o(branch_pipe_ready_i),
      .valid_i(valid_branch_fork),

      .out(branch_data),
      .ready_i(branch_ready_i),
      .valid_o(branch_valid_o)
  );

  // Control-Status
  hs_skid_buffer #(
      .WIDTH($bits(ctrlstatus_data))
  ) issue_2_ctrlstatus (
      .clk_core,
      .rst_core_n,

      .flush(flush_req),

      .in(fork_ctrlstatus_data),
      .ready_o(ctrlstatus_pipe_ready_i),
      .valid_i(valid_ctrlstatus_fork),

      .out(ctrlstatus_data),
      .ready_i(ctrlstatus_ready_i),
      .valid_o(ctrlstatus_valid_o)
  );

  always_ff @(posedge clk_core or negedge rst_core_n) begin
    if (~rst_core_n) flush_ack <= 1;
    else flush_ack <= flush_req;
  end

endmodule
