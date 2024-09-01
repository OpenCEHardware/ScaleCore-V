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
    output branch_data_t branch_data,
    output ctrl_status_data_t ctrl_status_data,
    output mem_data_t mem_data,

    input logic alu_ready_i,
    input logic branch_ready_i,
    input logic ctrl_status_ready_i,
    input logic mem_ready_i,

    output logic alu_valid_o,
    output logic branch_valid_o,
    output logic ctrl_status_valid_o,
    output logic mem_valid_o,

    // Regfile signals
    input reg_addr wr_addr,
    input word wr_data,
    input logic wr_en

);

  // Regfile
  reg_addr rs1_addr;
  reg_addr rs2_addr;
  word rs1_data;
  word rs2_data;

  // Masking unit
  reg_mask mask;
  reg_mask rd_mask;
  issue_data_t issue_data_masking;
  logic valid_maksing;

  // Muxing unit
  alu_data_t mux_alu_data;
  branch_data_t mux_branch_data;
  ctrl_status_data_t mux_ctrl_status_data;
  mem_data_t mux_mem_data;
  logic valid_alu_mux;
  logic valid_branch_mux;
  logic valid_ctrl_status_mux;
  logic valid_mem_mux;

  // Pipes and stalls
  // TODO: Check if we want so much freefloating logic in top modules
  logic alu_pipe_ready_i;
  logic branch_pipe_ready_i;
  logic ctrl_status_pipe_ready_i;
  logic mem_pipe_ready_i;

  logic alu_stall;
  logic branch_stall;
  logic ctrl_status_stall;
  logic mem_stall;

  logic stall;
  logic hazard;
  logic hazard_stall;
  logic exec_mem_stall;

  assign stall = hazard_stall | exec_mem_stall;
  assign hazard_stall = valid_i & hazard;
  assign exec_mem_stall = alu_stall | branch_stall | ctrl_status_stall | mem_stall;
  assign ready_o = ~stall;

  // Register File
  hsv_core_regfile reg_file (
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

  // First stage: Masking Logic
  hsv_core_masking masking (
      .clk_core,

      .stall,
      .flush_req,

      .issue_data,
      .valid_i,

      .mask,
      .rd_mask,
      .out(issue_data_masking),
      .valid_o(valid_maksing),

      .rs1_addr,
      .rs2_addr
  );

  // Second stage: Muxing Logic
  hsv_core_muxing muxing (
      .clk_core,

      .stall,
      .alu_stall,
      .branch_stall,
      .ctrl_status_stall,
      .mem_stall,
      .exec_mem_stall,
      .flush_req,

      .issue_data(issue_data_masking),
      .mask,
      .rd_mask,
      .rs1_data,
      .rs2_data,
      .valid_i(valid_maksing),

      .alu_valid_o(valid_alu_mux),
      .branch_valid_o(valid_branch_mux),
      .ctrl_status_valid_o(valid_ctrl_status_mux),
      .mem_valid_o(valid_mem_mux),

      .alu_data(mux_alu_data),
      .branch_data(mux_branch_data),
      .ctrl_status_data(mux_ctrl_status_data),
      .mem_data(mux_mem_data),

      .hazard
  );

  // Third stage: Buffering pipelines (one skid buffer per PU in exec-mem)
  // ALU
  hs_skid_buffer #(
      .WIDTH($bits(alu_data))
  ) issue_2_alu (
      .clk_core,
      .rst_core_n,

      .stall(alu_stall),
      .flush_req,

      .in(mux_alu_data),
      .ready_o(alu_pipe_ready_i),
      .valid_i(valid_alu_mux),

      .out(alu_data),
      .ready_i(alu_ready_i),
      .valid_o(alu_valid_o)
  );

  // Branch
  hs_skid_buffer #(
      .WIDTH($bits(branch_data))
  ) issue_2_branch (
      .clk_core,
      .rst_core_n,

      .stall(branch_stall),
      .flush_req,

      .in(mux_branch_data),
      .ready_o(branch_pipe_ready_i),
      .valid_i(valid_branch_mux),

      .out(branch_data),
      .ready_i(branch_ready_i),
      .valid_o(branch_valid_o)
  );

  // Control-Status
  hs_skid_buffer #(
      .WIDTH($bits(ctrl_status_data))
  ) issue_2_ctrl_status (
      .clk_core,
      .rst_core_n,

      .stall(ctrl_status_stall),
      .flush_req,

      .in(mux_ctrl_status_data),
      .ready_o(ctrl_status_pipe_ready_i),
      .valid_i(valid_ctrl_status_mux),

      .out(ctrl_status_data),
      .ready_i(ctrl_status_ready_i),
      .valid_o(ctrl_status_valid_o)
  );

  // Memory
  hs_skid_buffer #(
      .WIDTH($bits(mem_data))
  ) issue_2_memory (
      .clk_core,
      .rst_core_n,

      .stall(mem_stall),
      .flush_req,

      .in(mux_mem_data),
      .ready_o(mem_pipe_ready_i),
      .valid_i(valid_mem_mux),

      .out(mem_data),
      .ready_i(mem_ready_i),
      .valid_o(mem_valid_o)
  );

  always_ff @(posedge clk_core or negedge rst_core_n) begin
    if (~rst_core_n) flush_ack <= 0;
    else flush_ack <= flush_req;
  end

endmodule
