module hsv_core_commit
  import hsv_core_pkg::*;
(
    input logic clk_core,
    input logic rst_core_n,

    // Flush signals
    input  word  flush_target,
    input  logic flush_req,
    output logic flush_ack,

    // Input Channel (sink) signals
    input commit_data_t alu_data,
    input commit_data_t branch_data,
    input commit_data_t ctrlstatus_data,
    input commit_data_t mem_data,
    input commit_data_t foo_data,

    input logic alu_valid_i,
    input logic branch_valid_i,
    input logic ctrlstatus_valid_i,
    input logic mem_valid_i,
    input logic foo_valid_i,

    output logic alu_ready_o,
    output logic branch_ready_o,
    output logic ctrlstatus_ready_o,
    output logic mem_ready_o,
    output logic foo_ready_o,

    // Output Channel (source) signals
    // Commit is not a ready-valid source module

    // Control signals
    output logic alu_commit_o,
    output logic branch_commit_o,
    output logic ctrlstatus_commit_o,
    output logic mem_commit_o,
    output logic foo_commit_o,

    output logic       ctrl_flush_begin,
    output logic       ctrl_trap,
    output exception_t ctrl_trap_cause,
    output word        ctrl_trap_value,
    output logic       ctrl_mode_return,
    output word        ctrl_next_pc,
    output logic       ctrl_commit,
    output logic       ctrl_wait_irq,
    input  logic       ctrl_begin_irq,

    // Refile writeback signals
    output reg_addr wr_addr,
    output word wr_data,
    output logic wr_en,

    output insn_token token,
    // Issue feedback signals
    output reg_mask   commit_mask
);

  logic alu_trap, foo_trap, mem_trap, branch_trap, ctrlstatus_trap;
  commit_action_bits_t action;

  // Extract individual flush/trap/wfi/etc bits
  assign action = used_data.action;

  assign alu_trap = alu_data.trap;
  assign branch_trap = branch_data.trap;
  assign ctrlstatus_trap = ctrlstatus_data.trap;
  assign mem_trap = mem_data.trap;
  assign foo_trap = foo_data.trap;

  assign alu_ready_o = token == alu_data.common.token;
  assign branch_ready_o = token == branch_data.common.token;
  assign ctrlstatus_ready_o = token == ctrlstatus_data.common.token;
  assign mem_ready_o = token == mem_data.common.token;
  assign foo_ready_o = token == foo_data.common.token;

  logic alu_committable;
  logic branch_committable;
  logic ctrlstatus_committable;
  logic mem_committable;
  logic foo_committable;

  assign alu_committable = alu_ready_o & alu_valid_i;
  assign branch_committable = branch_ready_o & branch_valid_i;
  assign ctrlstatus_committable = ctrlstatus_ready_o & ctrlstatus_valid_i;
  assign mem_committable = mem_ready_o & mem_valid_i;
  assign foo_committable = foo_ready_o & foo_valid_i;

  assign alu_commit_o = !alu_trap & alu_committable;
  assign branch_commit_o = !branch_trap & branch_committable;
  assign ctrlstatus_commit_o = !ctrlstatus_trap & ctrlstatus_committable;
  assign mem_commit_o = !mem_trap & mem_committable;
  assign foo_commit_o = !foo_trap & foo_committable;

  logic general_commit;
  assign ctrl_commit = general_commit;

  assign general_commit
  = alu_commit_o
  | branch_commit_o
  | ctrlstatus_commit_o
  | mem_commit_o
  | foo_commit_o;

  commit_data_t alu_committable_data;
  commit_data_t branch_committable_data;
  commit_data_t ctrlstatus_committable_data;
  commit_data_t mem_committable_data;
  commit_data_t foo_committable_data;

  assign alu_committable_data = alu_committable ? alu_data : '0;
  assign branch_committable_data = branch_committable ? branch_data : '0;
  assign ctrlstatus_committable_data = ctrlstatus_committable ? ctrlstatus_data : '0;
  assign mem_committable_data = mem_committable ? mem_data : '0;
  assign foo_committable_data = foo_committable ? foo_data : '0;

  commit_data_t used_data;

  assign used_data
  = alu_committable_data
  | branch_committable_data
  | ctrlstatus_committable_data
  | mem_committable_data
  | foo_committable_data;

  assign ctrl_flush_begin = action.flush;

  assign wr_en = used_data.writeback & !action.trap;
  assign wr_addr = used_data.common.rd_addr;
  assign wr_data = used_data.result;
  assign commit_mask = !action.trap ? used_data.common.rd_mask : '0;

  logic token_enable;
  assign token_enable = !ctrl_begin_irq & general_commit & !action.flush;
  logic token_clear;
  assign token_clear = flush_ack & !flush_req;

  always_ff @(posedge clk_core) begin

    if (token_enable) token <= token + 1;

    ctrl_trap <= action.trap;
    ctrl_wait_irq <= action.wait_irq;
    ctrl_trap_cause <= used_data.exception_cause;
    ctrl_trap_value <= used_data.exception_value;
    ctrl_mode_return <= action.mode_return;

    if (!action.trap) ctrl_next_pc <= used_data.next_pc;

    if (token_clear) begin
      token <= '0;
      ctrl_next_pc <= flush_target;
    end
  end

  always_ff @(posedge clk_core or negedge rst_core_n) begin
    if (~rst_core_n) flush_ack <= 1;
    else flush_ack <= flush_req;
  end

endmodule
