module hsv_core_ctrlstatus_counters
  import hsv_core_pkg::*, hsv_core_ctrlstatus_regs_pkg::*;
(
    input logic clk_core,
    input logic rst_core_n,

    input  hsv_core_ctrlstatus_regs__out_t                     regs_i,
    output hsv_core_ctrlstatus_regs__MCYCLE__external__in_t    mcycle_o,
    output hsv_core_ctrlstatus_regs__MINSTRET__external__in_t  minstret_o,
    output hsv_core_ctrlstatus_regs__MCYCLEH__external__in_t   mcycleh_o,
    output hsv_core_ctrlstatus_regs__MINSTRETH__external__in_t minstreth_o,
    output hsv_core_ctrlstatus_regs__CYCLE__external__in_t     cycle_o,
    output hsv_core_ctrlstatus_regs__TIME__external__in_t      time_o,
    output hsv_core_ctrlstatus_regs__INSTRET__external__in_t   instret_o,
    output hsv_core_ctrlstatus_regs__CYCLEH__external__in_t    cycleh_o,
    output hsv_core_ctrlstatus_regs__TIMEH__external__in_t     timeh_o,
    output hsv_core_ctrlstatus_regs__INSTRETH__external__in_t  instreth_o,

    input logic ctrl_commit
);

  word time_hi, time_lo, time_lo_next;
  word cycles_hi, cycles_lo, cycles_lo_next;
  word committed_hi, committed_lo, committed_lo_next;
  logic time_overflow, cycles_overflow, committed_overflow;

  function automatic word update(word current, word next, word mask);
    return (next & mask) | (current & ~mask);
  endfunction

  assign mcycle_o.rd_ack = regs_i.MCYCLE.req & ~regs_i.MCYCLE.req_is_wr;
  assign mcycle_o.wr_ack = regs_i.MCYCLE.req & regs_i.MCYCLE.req_is_wr;
  assign mcycle_o.rd_data = cycles_lo;

  assign minstret_o.rd_ack = regs_i.MINSTRET.req & ~regs_i.MINSTRET.req_is_wr;
  assign minstret_o.wr_ack = regs_i.MINSTRET.req & regs_i.MINSTRET.req_is_wr;
  assign minstret_o.rd_data = committed_lo;

  assign mcycleh_o.rd_ack = regs_i.MCYCLEH.req & ~regs_i.MCYCLEH.req_is_wr;
  assign mcycleh_o.wr_ack = regs_i.MCYCLEH.req & regs_i.MCYCLEH.req_is_wr;
  assign mcycleh_o.rd_data = cycles_hi;

  assign minstreth_o.rd_ack = regs_i.MINSTRETH.req & ~regs_i.MINSTRETH.req_is_wr;
  assign minstreth_o.wr_ack = regs_i.MINSTRETH.req & regs_i.MINSTRETH.req_is_wr;
  assign minstreth_o.rd_data = committed_hi;

  assign cycle_o.rd_ack = regs_i.CYCLE.req & ~regs_i.CYCLE.req_is_wr;
  assign cycle_o.rd_data = cycles_lo;

  assign time_o.rd_ack = regs_i.TIME.req & ~regs_i.TIME.req_is_wr;
  assign time_o.rd_data = time_lo;

  assign instret_o.rd_ack = regs_i.INSTRET.req & ~regs_i.INSTRET.req_is_wr;
  assign instret_o.rd_data = committed_lo;

  assign cycleh_o.rd_ack = regs_i.CYCLEH.req & ~regs_i.CYCLEH.req_is_wr;
  assign cycleh_o.rd_data = cycles_hi;

  assign timeh_o.rd_ack = regs_i.TIMEH.req & ~regs_i.TIMEH.req_is_wr;
  assign timeh_o.rd_data = time_hi;

  assign instreth_o.rd_ack = regs_i.INSTRETH.req & ~regs_i.INSTRETH.req_is_wr;
  assign instreth_o.rd_data = committed_hi;

  assign {time_overflow, time_lo_next} = {1'b0, time_lo} + 1;
  assign {cycles_overflow, cycles_lo_next} = {1'b0, cycles_lo} + 1;
  assign {committed_overflow, committed_lo_next} = {1'b0, committed_lo} + 1;

  always_ff @(posedge clk_core or negedge rst_core_n)
    if (~rst_core_n) begin
      time_lo <= '0;
      time_hi <= '0;
      cycles_lo <= '0;
      cycles_hi <= '0;
      committed_lo <= '0;
      committed_hi <= '0;
    end else begin
      time_lo <= time_lo_next;
      if (time_overflow) time_hi <= time_hi + 1;

      cycles_lo <= cycles_lo_next;
      if (cycles_overflow) cycles_hi <= cycles_hi + 1;

      if (mcycle_o.wr_ack)
        cycles_lo <= update(cycles_lo, regs_i.MCYCLE.wr_data, regs_i.MCYCLE.wr_biten);

      if (mcycleh_o.wr_ack)
        cycles_hi <= update(cycles_hi, regs_i.MCYCLEH.wr_data, regs_i.MCYCLEH.wr_biten);

      if (ctrl_commit) begin
        committed_lo <= committed_lo_next;
        if (committed_overflow) committed_hi <= committed_hi + 1;
      end

      if (minstret_o.wr_ack)
        committed_lo <= update(committed_lo, regs_i.MINSTRET.wr_data, regs_i.MINSTRET.wr_biten);

      if (minstreth_o.wr_ack)
        committed_hi <= update(committed_hi, regs_i.MINSTRETH.wr_data, regs_i.MINSTRETH.wr_biten);
    end

endmodule
