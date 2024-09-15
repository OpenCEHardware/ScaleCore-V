module hsv_core_ctrlstatus
  import hsv_core_pkg::*;
  import hsv_core_ctrlstatus_regs_pkg::*;
#(
    parameter word HART_ID = 0
) (
    input logic clk_core,
    input logic rst_core_n,
    input logic irq,

    output word  flush_target,
    output logic flush_req,
    input  logic flush_ack_fetch,
    input  logic flush_ack_decode,
    input  logic flush_ack_issue,
    input  logic flush_ack_alu,
    input  logic flush_ack_foo,
    input  logic flush_ack_mem,
    input  logic flush_ack_branch,
    input  logic flush_ack_commit,

    input ctrlstatus_data_t ctrlstatus_data,
    output logic ready_o,
    input logic valid_i,

    output commit_data_t commit_data,
    input logic ready_i,
    output logic valid_o,

    input  insn_token       commit_token,
    input  logic            ctrl_flush_begin,
    input  logic            ctrl_trap,
    input  logic      [4:0] ctrl_trap_cause,
    input  word             ctrl_trap_value,
    input  word             ctrl_next_pc,
    input  logic            ctrl_commit,
    output logic            ctrl_begin_irq
);

  // Increase this if you add another flush_ack_* signal
  localparam int NumOfFlushAcks = 9;

  logic flush_ack, flush_ack_falling, flush_ack_raising;
  logic [NumOfFlushAcks - 1:0] flush_acks;

  privilege_t current_mode;

  logic flush_ack_ctrlstatus, out_ready, out_valid;
  commit_data_t out;

  hsv_core_ctrlstatus_regs__in_t regs_in;
  hsv_core_ctrlstatus_regs__out_t regs_out;

  logic regs_req;
  logic regs_req_is_wr;
  logic [15:0] regs_addr;
  logic [31:0] regs_wr_data;
  logic [31:0] regs_wr_biten;
  logic regs_req_stall_wr;
  logic regs_req_stall_rd;
  logic regs_rd_ack;
  logic regs_rd_err;
  logic [31:0] regs_rd_data;
  logic regs_wr_ack;
  logic regs_wr_err;

  assign regs_in.MHARTID.rd_ack = regs_out.MHARTID.req & regs_out.MHARTID.req_is_wr;
  assign regs_in.MHARTID.rd_data.VALUE = HART_ID;

  assign flush_acks = {
    flush_ack_fetch,
    flush_ack_decode,
    flush_ack_issue,
    flush_ack_alu,
    flush_ack_foo,
    flush_ack_mem,
    flush_ack_branch,
    flush_ack_ctrlstatus,
    flush_ack_commit
  };

  // These are combined views of all flush acks, to be used by the global FSM.
  //
  // If all acks have the same value (all-0 or all-1), then both signals
  // hold that same value. If not all acks are the same (e.g. flush_ack_alu
  // is 1 while flush_ack_mem is 0), then we're undergoing a flush state
  // transition. If a flush is starting (flush_req == 1), the global FSM
  // should understand this situation the same as if a common ack were stil 0
  // (flush_ack_raising); if a flush is ending (flush_req == 0), the correct
  // ack signal (flush_ack_falling) holds 1 until all acks have fallen.
  assign flush_ack = flush_req ? flush_ack_raising : flush_ack_falling;
  assign flush_ack_raising = &flush_acks;
  assign flush_ack_falling = |flush_acks;

  hsv_core_ctrlstatus_fsm global_fsm (
      .clk_core,
      .rst_core_n,
      .irq,

      .flush_target,
      .flush_req,
      .flush_ack,

      .ctrl_flush_begin,
      .ctrl_trap,
      .ctrl_trap_cause,
      .ctrl_trap_value,
      .ctrl_next_pc,
      .ctrl_commit,
      .ctrl_begin_irq,

      .regs_i(regs_out),
      .mstatus_o(regs_in.MSTATUS),
      .mepc_o(regs_in.MEPC),
      .mcause_o(regs_in.MCAUSE),
      .mtval_o(regs_in.MTVAL),

      .current_mode
  );

  hsv_core_ctrlstatus_regs regs (
      .clk(clk_core),
      .arst_n(rst_core_n),

      .s_cpuif_req(regs_req),
      .s_cpuif_req_is_wr(regs_req_is_wr),
      .s_cpuif_addr(regs_addr),
      .s_cpuif_wr_data(regs_wr_data),
      .s_cpuif_wr_biten(regs_wr_biten),
      .s_cpuif_req_stall_wr(regs_req_stall_wr),
      .s_cpuif_req_stall_rd(regs_req_stall_rd),
      .s_cpuif_rd_ack(regs_rd_ack),
      .s_cpuif_rd_err(regs_rd_err),
      .s_cpuif_rd_data(regs_rd_data),
      .s_cpuif_wr_ack(regs_wr_ack),
      .s_cpuif_wr_err(regs_wr_err),

      .hwif_in (regs_in),
      .hwif_out(regs_out)
  );

  hsv_core_ctrlstatus_counters counters (
      .clk_core,
      .rst_core_n,

      .regs_i(regs_out),
      .mcycle_o(regs_in.MCYCLE),
      .minstret_o(regs_in.MINSTRET),
      .mcycleh_o(regs_in.MCYCLEH),
      .minstreth_o(regs_in.MINSTRETH),
      .cycle_o(regs_in.CYCLE),
      .time_o(regs_in.TIME),
      .instret_o(regs_in.INSTRET),
      .cycleh_o(regs_in.CYCLEH),
      .timeh_o(regs_in.TIMEH),
      .instreth_o(regs_in.INSTRETH),

      .ctrl_commit
  );

  hsv_core_ctrlstatus_readwrite readwrite (
      .clk_core,
      .rst_core_n,

      .flush_req,
      .flush_ack(flush_ack_ctrlstatus),

      .in(ctrlstatus_data),
      .ready_o,
      .valid_i,

      .out,
      .ready_i(out_ready),
      .valid_o(out_valid),

      .regs_req,
      .regs_req_is_wr,
      .regs_addr,
      .regs_wr_data,
      .regs_wr_biten,
      .regs_req_stall_wr,
      .regs_req_stall_rd,
      .regs_rd_ack,
      .regs_rd_err,
      .regs_rd_data,
      .regs_wr_ack,
      .regs_wr_err,

      .commit_token,
      .current_mode
  );

  hs_skid_buffer #(
      .WIDTH($bits(commit_data))
  ) ctrlstatus2commit (
      .clk_core,
      .rst_core_n,

      .flush(flush_req),

      .in(out),
      .ready_o(out_ready),
      .valid_i(out_valid),

      .out(commit_data),
      .ready_i,
      .valid_o
  );

endmodule
