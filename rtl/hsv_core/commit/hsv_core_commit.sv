module hsv_core_commit
  import hsv_core_pkg::*;
(
    input logic clk_core,
    input logic rst_core_n,

    // Flush signals
    input  logic flush_req,
    output logic flush_ack,

    // Input Channel (sink) signals
    input commit_data_t alu_data,
    input commit_data_t branch_data,
    input commit_data_t ctrl_status_data,
    input commit_data_t mem_data,
    input commit_data_t foo_data,

    input logic alu_valid_i,
    input logic branch_valid_i,
    input logic ctrl_status_valid_i,
    input logic mem_valid_i,
    input logic foo_valid_i,

    output logic alu_ready_o,
    output logic branch_ready_o,
    output logic ctrl_status_ready_o,
    output logic mem_ready_o,
    output logic foo_ready_o,

    // Output Channel (source) signals
    // Commit is not a ready-valid source module

    // Control signals
    output logic alu_commit_o,
    output logic branch_commit_o,
    output logic ctrl_status_commit_o,
    output logic mem_commit_o,
    output logic foo_commit_o,
    output logic ctrl_commmit,
    input  logic ctrl_begin_irq,

    output logic ctrl_flush_begin,
    output logic ctrl_trap,
    output [4:0] ctrl_trap_cause,  //Check size
    output [31:0] ctrl_trap_value,  //Check size
    output word ctrl_next_pc,

    // Refile writeback signals
    output reg_addr wr_addr,
    output word wr_data,
    output logic wr_en,

    // Issue feedback signals
    output reg_mask commit_mask

);
  insn_token token;

  logic alu_trap;
  logic branch_trap;
  logic ctrl_status_trap;
  logic mem_trap;
  logic foo_trap;

  assign alu_trap = alu_data.trap;
  assign branch_trap = branch_data.trap;
  assign ctrl_status_trap = ctrl_status_data.trap;
  assign mem_trap = mem_data.trap;
  assign foo_trap = foo_data.trap;

  assign alu_ready_o = token == alu_data.common.token;
  assign branch_ready_o = token == branch_data.common.token;
  assign ctrl_status_ready_o = token == ctrl_status_data.common.token;
  assign mem_ready_o = token == mem_data.common.token;
  assign foo_ready_o = token == foo_data.common.token;

  logic alu_committable;
  logic branch_committable;
  logic ctrl_status_committable;
  logic mem_committable;
  logic foo_committable;

  assign alu_committable = alu_ready_o & alu_valid_i;
  assign branch_committable = branch_ready_o & branch_valid_i;
  assign ctrl_status_committable = ctrl_status_ready_o & ctrl_status_valid_i;
  assign mem_committable = mem_ready_o & mem_valid_i;
  assign foo_committable = foo_ready_o & foo_valid_i;

  assign alu_commit_o = !alu_trap & alu_committable;
  assign branch_commit_o = !branch_trap & branch_committable;
  assign ctrl_status_commit_o = !ctrl_status_trap & ctrl_status_committable;
  assign mem_commit_o = !mem_trap & mem_committable;
  assign foo_commit_o = !foo_trap & foo_committable;

  logic general_commit;
  assign general_commit = alu_commit_o | branch_commit_o | ctrl_status_commit_o | mem_commit_o | foo_commit_o;
  assign ctrl_commmit = general_commit;

  commit_data_t used_data;

  always_comb begin : data_select
    if (alu_committable) used_data = alu_data;
    else if (branch_committable) used_data = branch_data;
    else if (ctrl_status_committable) used_data = ctrl_status_data;
    else if (mem_committable) used_data = mem_data;
    else if (foo_committable) used_data = foo_data;
  end

  assign ctrl_flush_begin = used_data.jump | used_data.trap;

  assign wr_addr = used_data.common.rd_addr;
  assign wr_data = used_data.result;
  assign wr_en = used_data.writeback & !used_data.trap;
  assign commit_mask = !used_data.trap ? used_data.rd_mask : '0;

  logic token_enable;
  assign token_enable = !ctrl_begin_irq & general_commit & !used_data.trap;
  logic token_clear;
  assign token_clear = flush_ack & !flush_req;

  always_ff @(posedge clk_core) begin

    if (token_enable) token <= token + 1;
    if (token_clear) token <= '0;

    ctrl_trap <= used_data.trap;
    ctrl_trap_cause <= used_data.trap_cause;
    ctrl_trap_value <= used_data.trap_value;

    if (!used_data.trap) ctrl_next_pc <= used_data.next_pc;

  end

  always_ff @(posedge clk_core or negedge rst_core_n) begin
    if (~rst_core_n) flush_ack <= 0;
    else flush_ack <= flush_req;
  end

endmodule