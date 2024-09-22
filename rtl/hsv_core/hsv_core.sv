module hsv_core
  import hsv_core_pkg::*;
#(
    parameter word HART_ID         = 0,
    parameter int  FETCH_BURST_LEN = 4
) (
    input logic clk_core,
    input logic rst_core_n,

    axib_if.m imem,
    axil_if.m dmem,

    input logic irq_core
);

  word  flush_target;
  logic flush_req;
  logic flush_ack_fetch, flush_ack_decode, flush_ack_issue, flush_ack_commit;
  logic flush_ack_alu, flush_ack_foo, flush_ack_mem, flush_ack_branch;

  logic fetch_valid, decode_ready;
  fetch_data_t fetch_data;

  logic decode_valid, issue_ready;
  issue_data_t issue_data;

  logic
      alu_issue_ready, foo_issue_ready, mem_issue_ready, branch_issue_ready, ctrlstatus_issue_ready;
  logic
      issue_alu_valid, issue_foo_valid, issue_mem_valid, issue_branch_valid, issue_ctrlstatus_valid;
  alu_data_t alu_data;
  foo_data_t foo_data;
  mem_data_t mem_data;
  branch_data_t branch_data;
  ctrlstatus_data_t ctrlstatus_data;

  logic
      commit_alu_ready,
      commit_foo_ready,
      commit_mem_ready,
      commit_branch_ready,
      commit_ctrlstatus_ready;
  logic
      alu_commit_valid,
      foo_commit_valid,
      mem_commit_valid,
      branch_commit_valid,
      ctrlstatus_commit_valid;
  commit_data_t alu_commit, foo_commit, mem_commit, branch_commit, ctrlstatus_commit;

  logic commit_is_alu, commit_is_foo, commit_is_mem, commit_is_branch, commit_is_ctrlstatus;
  reg_mask   commit_mask;
  insn_token commit_token;

  word ctrl_next_pc, ctrl_trap_value;
  logic ctrl_begin_irq, ctrl_commit, ctrl_flush_begin, ctrl_mode_return, ctrl_trap, ctrl_wait_irq;
  exception_t ctrl_trap_cause;
  privilege_t current_mode;

  word regfile_rs1_data, regfile_rs2_data, regfile_wr_data;
  logic regfile_wr_en;
  reg_addr regfile_rs1_addr, regfile_rs2_addr, regfile_wr_addr;

  hsv_core_fetch #(
      .BURST_LEN(FETCH_BURST_LEN)
  ) fetch (
      .clk_core,
      .rst_core_n,

      .flush_target,
      .flush_req,
      .flush_ack(flush_ack_fetch),

      .fetch_data,
      .ready_i(decode_ready),
      .valid_o(fetch_valid),

      .imem
  );

  hsv_core_decode decode (
      .clk_core,
      .rst_core_n,

      .flush_req,
      .flush_ack(flush_ack_decode),

      .fetch_data,
      .ready_o(decode_ready),
      .valid_i(fetch_valid),

      .issue_data,
      .ready_i(issue_ready),
      .valid_o(decode_valid),

      .current_mode
  );

  hsv_core_issue issue (
      .clk_core,
      .rst_core_n,

      .flush_req,
      .flush_ack(flush_ack_issue),

      .issue_data,
      .ready_o(issue_ready),
      .valid_i(decode_valid),

      .alu_data,
      .alu_ready_i(alu_issue_ready),
      .alu_valid_o(issue_alu_valid),

      .foo_data,
      .foo_ready_i(foo_issue_ready),
      .foo_valid_o(issue_foo_valid),

      .mem_data,
      .mem_ready_i(mem_issue_ready),
      .mem_valid_o(issue_mem_valid),

      .branch_data,
      .branch_ready_i(branch_issue_ready),
      .branch_valid_o(issue_branch_valid),

      .ctrlstatus_data,
      .ctrlstatus_ready_i(ctrlstatus_issue_ready),
      .ctrlstatus_valid_o(issue_ctrlstatus_valid),

      .rs1_addr(regfile_rs1_addr),
      .rs2_addr(regfile_rs2_addr),
      .rs1_data(regfile_rs1_data),
      .rs2_data(regfile_rs2_data),

      .commit_mask
  );

  hsv_core_alu alu (
      .clk_core,
      .rst_core_n,

      .flush_req,
      .flush_ack(flush_ack_alu),

      .alu_data,
      .ready_o(alu_issue_ready),
      .valid_i(issue_alu_valid),

      .commit_data(alu_commit),
      .ready_i(commit_alu_ready),
      .valid_o(alu_commit_valid)
  );

  hsv_core_foo foo (
      .clk_core,
      .rst_core_n,

      .flush_req,
      .flush_ack(flush_ack_foo),

      .foo_data,
      .ready_o(foo_issue_ready),
      .valid_i(issue_foo_valid),

      .commit_data(foo_commit),
      .ready_i(commit_foo_ready),
      .valid_o(foo_commit_valid)
  );

  hsv_core_mem mem (
      .clk_core,
      .rst_core_n,

      .flush_req,
      .flush_ack(flush_ack_mem),

      .mem_data,
      .ready_o(mem_issue_ready),
      .valid_i(issue_mem_valid),

      .commit_data(mem_commit),
      .ready_i(commit_mem_ready),
      .valid_o(mem_commit_valid),

      .commit_mem(commit_is_mem),
      .commit_token,

      .dmem
  );

  hsv_core_branch branch (
      .clk_core,
      .rst_core_n,

      .flush_req,
      .flush_ack(flush_ack_branch),

      .branch_data,
      .ready_o(branch_issue_ready),
      .valid_i(issue_branch_valid),

      .commit_data(branch_commit),
      .ready_i(commit_branch_ready),
      .valid_o(branch_commit_valid)
  );

  hsv_core_ctrlstatus #(
      .HART_ID
  ) ctrlstatus (
      .clk_core,
      .rst_core_n,
      .irq(irq_core),

      .flush_target,
      .flush_req,
      .flush_ack_fetch,
      .flush_ack_decode,
      .flush_ack_issue,
      .flush_ack_alu,
      .flush_ack_foo,
      .flush_ack_mem,
      .flush_ack_branch,
      .flush_ack_commit,

      .ctrlstatus_data,
      .ready_o(ctrlstatus_issue_ready),
      .valid_i(issue_ctrlstatus_valid),

      .commit_data(ctrlstatus_commit),
      .ready_i(commit_ctrlstatus_ready),
      .valid_o(ctrlstatus_commit_valid),

      .commit_token,

      .ctrl_flush_begin,
      .ctrl_trap,
      .ctrl_trap_cause,
      .ctrl_trap_value,
      .ctrl_mode_return,
      .ctrl_next_pc,
      .ctrl_commit,
      .ctrl_wait_irq,
      .ctrl_begin_irq,

      .current_mode
  );

  hsv_core_commit commit (
      .clk_core,
      .rst_core_n,

      .flush_target,
      .flush_req,
      .flush_ack(flush_ack_commit),

      .alu_data(alu_commit),
      .alu_ready_o(commit_alu_ready),
      .alu_valid_i(alu_commit_valid),

      .foo_data(foo_commit),
      .foo_ready_o(commit_foo_ready),
      .foo_valid_i(foo_commit_valid),

      .mem_data(mem_commit),
      .mem_ready_o(commit_mem_ready),
      .mem_valid_i(mem_commit_valid),

      .branch_data(branch_commit),
      .branch_ready_o(commit_branch_ready),
      .branch_valid_i(branch_commit_valid),

      .ctrlstatus_data(ctrlstatus_commit),
      .ctrlstatus_ready_o(commit_ctrlstatus_ready),
      .ctrlstatus_valid_i(ctrlstatus_commit_valid),

      .alu_commit_o(commit_is_alu),
      .foo_commit_o(commit_is_foo),
      .mem_commit_o(commit_is_mem),
      .branch_commit_o(commit_is_branch),
      .ctrlstatus_commit_o(commit_is_ctrlstatus),

      .ctrl_flush_begin,
      .ctrl_trap,
      .ctrl_trap_cause,
      .ctrl_trap_value,
      .ctrl_mode_return,
      .ctrl_next_pc,
      .ctrl_commit,
      .ctrl_wait_irq,
      .ctrl_begin_irq,

      .wr_en  (regfile_wr_en),
      .wr_addr(regfile_wr_addr),
      .wr_data(regfile_wr_data),

      .token(commit_token),
      .commit_mask
  );

  hsv_core_regfile regfile (
      .clk_core,
      .rst_core_n,

      .rs1_addr(regfile_rs1_addr),
      .rs2_addr(regfile_rs2_addr),
      .wr_addr(regfile_wr_addr),
      .wr_data(regfile_wr_data),
      .wr_en(regfile_wr_en),
      .rs1_data(regfile_rs1_data),
      .rs2_data(regfile_rs2_data)
  );

endmodule
