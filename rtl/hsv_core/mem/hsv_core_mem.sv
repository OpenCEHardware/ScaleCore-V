module hsv_core_mem
  import hsv_core_pkg::*;
#(
    int IO_FIFO_DEPTH      = 8,
    int PENDING_FIFO_DEPTH = 8
) (
    input logic clk_core,
    input logic rst_core_n,

    input  logic flush_req,
    output logic flush_ack,

    input  mem_data_t mem_data,
    output logic      ready_o,
    input  logic      valid_i,

    output commit_data_t commit_data,
    input  logic         ready_i,
    output logic         valid_o,

    input logic      commit_mem,
    input insn_token commit_token,

    axib_if.m dmem
);

  logic dmem_ar_stall, dmem_aw_stall, dmem_w_stall;
  read_write_t transaction, request_fifo_out, response_fifo_out;

  word pending_read_address, pending_write_address, pending_write_completed_address;
  word pending_reads_peek[PENDING_FIFO_DEPTH], pending_writes_peek[PENDING_FIFO_DEPTH];
  logic pending_reads_ready, pending_reads_stall, pending_writes_ready, pending_writes_stall;
  logic [PENDING_FIFO_DEPTH - 1:0] pending_reads_peek_valid, pending_writes_peek_valid;

  logic request_fifo_in_ready, request_fifo_in_valid, request_fifo_in_stall;
  logic request_fifo_out_ready, request_fifo_out_valid, request_fifo_out_stall;

  logic response_fifo_in_ready, response_fifo_in_valid, response_fifo_in_stall;
  logic response_fifo_out_ready, response_fifo_out_valid, response_fifo_out_stall;

  // Burst signals - unused by current implementation

  assign dmem.arid = '0;
  assign dmem.arlen = '0;
  assign dmem.arsize = AXI_SIZE_4;
  assign dmem.arburst = AXI_BURST_INCR;

  assign dmem.awid = '0;
  assign dmem.awlen = '0;
  assign dmem.awsize = AXI_SIZE_4;
  assign dmem.awburst = AXI_BURST_INCR;

  assign dmem.wlast = 1;

  // The request and response modules share three counters:
  //
  // pending_reads (unsigned):
  //   Number of read requests sent over dmem.AR for which no response has
  //   made it to dmem.R yet
  //   - Incremented by request
  //   - Decremented by response
  //
  // pending_writes (unsigned):
  //   Number of write requests sent over dmem.AR and dmem.W for which no
  //   response has made it to dmem.B yet
  //   - Incremented by request
  //   - Decremented by response
  //
  // write_balance (signed):
  //   Number of committed writes that have not been executed yet.
  //   - Decremented by request
  //   - Incremented by response
  //
  //   Problem statement: A write cannot start before commit has acknowledged it,
  //   because writes have side effects, unlike memory reads. Consider a
  //   write instruction following a branch: the write may need to be discarded
  //   (as if it were never executed in the first place) if the branch is taken.
  //   Once commit expects a write, that write is sure to finish and can start.
  //   This would result in write serialization: only one write would be able to
  //   run at a time, as commit won't advance until the currently waited-for
  //   instruciton reaches it. The pipeline becomes useless this way.
  //
  //   Solution: The response module "lies" to commit by passing on writes
  //   that have not started yet and tracking them with the "write balance"
  //   counter. The request module can safely dispatch as many writes as this
  //   counter allows, decrementing it once per launched write. The counter
  //   can become negative if commit directly permits a write to start before
  //   the response module has had enough time to emit the corresponding write
  //   completion; this situation will fix itself once the completion reaches
  //   commit and the counter increments, returning to zero.
  //
  // Since AXI does not guarantee any ordering between reads and writes, no
  // reads can start unless pending_writes == 0, and likewise no writes can
  // start unless pending_reads == 0.
  //
  // All three counters must simultaneously equal zero before a flush can
  // proceed. This ensures completion of in-flight transactions.

  logic pending_reads_up, pending_reads_down;
  logic pending_writes_up, pending_writes_down;
  logic write_balance_up, write_balance_down;
  mem_counter pending_reads, pending_writes, write_balance;

  logic fence_ready, fence_valid;

  logic commit_stall, out_ready, out_valid;
  commit_data_t out_response;

  assign commit_stall = ~out_ready;

  // A requested flush can proceed once all pending reads and writes have completed
  logic can_flush;
  assign can_flush = (pending_reads == '0) & (pending_writes == '0) & (write_balance == '0);

  assign ready_o = ~request_fifo_in_stall & ~response_fifo_in_stall;

  assign request_fifo_in_stall = ~request_fifo_in_ready & request_fifo_in_valid;
  assign request_fifo_out_ready = ~request_fifo_out_stall;

  assign response_fifo_in_stall = ~response_fifo_in_ready & response_fifo_in_valid;
  assign response_fifo_out_ready = ~response_fifo_out_stall;

  assign dmem_w_stall = ~dmem.wready & dmem.wvalid;
  assign dmem_ar_stall = ~dmem.arready & dmem.arvalid;
  assign dmem_aw_stall = ~dmem.awready & dmem.awvalid;

  assign pending_reads_stall = ~pending_reads_ready;
  assign pending_writes_stall = ~pending_writes_ready;

  hsv_core_mem_address address_stage (
      .clk_core,

      .flush(flush_ack),
      .request_stall (request_fifo_in_stall),
      .response_stall(response_fifo_in_stall),

      .mem_data,
      .valid_i,

      .transaction,
      .request_valid_o (request_fifo_in_valid),
      .response_valid_o(response_fifo_in_valid)
  );

  hsv_core_fifo #(
      .WIDTH($bits(read_write_t)),
      .DEPTH(IO_FIFO_DEPTH)
  ) request_fifo (
      .clk_core,
      .rst_core_n,

      .flush(flush_ack),

      .in(transaction),
      .ready_o(request_fifo_in_ready),
      .valid_i(request_fifo_in_valid),

      .out(request_fifo_out),
      .ready_i(request_fifo_out_ready),
      .valid_o(request_fifo_out_valid)
  );

  hsv_core_mem_request #(
      .PENDING_FIFO_DEPTH(PENDING_FIFO_DEPTH)
  ) request_stage (
      .clk_core,
      .rst_core_n,

      .flush(flush_ack),
      .flush_req,
      .dmem_w_stall,
      .dmem_ar_stall,
      .dmem_aw_stall,
      .request_stall(request_fifo_out_stall),
      .pending_reads_stall,
      .pending_writes_stall,

      .request(request_fifo_out),
      .valid_i(request_fifo_out_valid),

      .fence_ready,
      .fence_valid,
      .pending_reads,
      .pending_reads_up,
      .pending_read_address,
      .pending_writes,
      .pending_writes_up,
      .pending_write_address,
      .write_balance,
      .write_balance_down,

      .dmem_w_valid (dmem.wvalid),
      .dmem_w_data  (dmem.wdata),
      .dmem_w_strobe(dmem.wstrb),

      .dmem_ar_valid  (dmem.arvalid),
      .dmem_ar_address(dmem.araddr),

      .dmem_aw_valid  (dmem.awvalid),
      .dmem_aw_address(dmem.awaddr),

      .commit_token,

      .pending_reads_peek,
      .pending_reads_peek_valid,
      .pending_writes_peek,
      .pending_writes_peek_valid
  );

  hsv_core_fifo #(
      .WIDTH($bits(read_write_t)),
      .DEPTH(IO_FIFO_DEPTH)
  ) response_fifo (
      .clk_core,
      .rst_core_n,

      .flush(flush_ack),

      .in(transaction),
      .ready_o(response_fifo_in_ready),
      .valid_i(response_fifo_in_valid),

      .out(response_fifo_out),
      .ready_i(response_fifo_out_ready),
      .valid_o(response_fifo_out_valid)
  );

  hsv_core_mem_response response_stage (
      .clk_core,
      .rst_core_n,

      .flush(flush_ack),
      .commit_stall,
      .response_stall(response_fifo_out_stall),

      .response(response_fifo_out),
      .valid_i (response_fifo_out_valid),

      .fence_ready,
      .fence_valid,
      .pending_reads_down,
      .pending_writes_down,
      .write_balance_up,

      .pending_reads,
      .pending_writes,
      .pending_write_completed_address,

      .dmem_r_valid(dmem.rvalid),
      .dmem_r_data (dmem.rdata),
      .dmem_r_resp (axi_resp_t'(dmem.rresp)),
      .dmem_r_ready(dmem.rready),

      .dmem_b_valid(dmem.bvalid),
      .dmem_b_resp (axi_resp_t'(dmem.bresp)),
      .dmem_b_ready(dmem.bready),

      .commit_mem,
      .valid_o(out_valid),

      .out(out_response)
  );

  hsv_core_skid_buffer #(
      .WIDTH($bits(commit_data))
  ) mem_2_commit (
      .clk_core,
      .rst_core_n,

      .flush(flush_req),

      .in(out_response),
      .ready_o(out_ready),
      .valid_i(out_valid),

      .out(commit_data),
      .ready_i,
      .valid_o
  );

  hsv_core_mem_counter pending_reads_counter (
      .clk_core,
      .rst_core_n,

      .up  (pending_reads_up),
      .down(pending_reads_down),
      .flush(flush_ack),

      .value(pending_reads)
  );

  hsv_core_fifo_peek #(
      .WIDTH($bits(word)),
      .DEPTH(PENDING_FIFO_DEPTH)
  ) pending_reads_fifo (
      .clk_core,
      .rst_core_n,

      .flush(0),

      .in(pending_read_address),
      .ready_o(pending_reads_ready),
      .valid_i(pending_reads_up),

      .out(/* not connected */),
      .ready_i(pending_reads_down),
      .valid_o(/* not connected */),

      .peek_valid(pending_reads_peek_valid),
      .peek_window(pending_reads_peek)
  );

  hsv_core_mem_counter pending_writes_counter (
      .clk_core,
      .rst_core_n,

      .up  (pending_writes_up),
      .down(pending_writes_down),
      .flush(flush_ack),

      .value(pending_writes)
  );

  hsv_core_fifo_peek #(
      .WIDTH($bits(word)),
      .DEPTH(PENDING_FIFO_DEPTH)
  ) pending_writes_fifo (
      .clk_core,
      .rst_core_n,

      .flush(0),

      .in(pending_write_address),
      .ready_o(pending_writes_ready),
      .valid_i(pending_writes_up),

      .out(pending_write_completed_address),
      .ready_i(pending_writes_down),
      .valid_o(/* not connected */),

      .peek_valid(pending_writes_peek_valid),
      .peek_window(pending_writes_peek)
  );

  hsv_core_mem_counter write_balance_counter (
      .clk_core,
      .rst_core_n,

      .up  (write_balance_up),
      .down(write_balance_down),
      .flush(flush_ack),

      .value(write_balance)
  );

  always_ff @(posedge clk_core or negedge rst_core_n)
    if (~rst_core_n) begin
      flush_ack <= 1;
    end else begin
      flush_ack <= flush_req & can_flush;
    end

endmodule
