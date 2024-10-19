module hsv_core_mem_request
  import hsv_core_pkg::*;
#(
    int PENDING_FIFO_DEPTH = 8
) (
    input logic clk_core,
    input logic rst_core_n,

    input logic flush,
    input logic flush_req,

    input  logic dmem_w_stall,
    input  logic dmem_ar_stall,
    input  logic dmem_aw_stall,
    input  logic pending_reads_stall,
    input  logic pending_writes_stall,
    output logic request_stall,

    input read_write_t request,
    input logic        valid_i,

    input  logic       fence_ready,
    output logic       fence_valid,
    input  mem_counter pending_reads,
    output logic       pending_reads_up,
    output word        pending_read_address,
    input  mem_counter pending_writes,
    output logic       pending_writes_up,
    output word        pending_write_address,
    input  mem_counter write_balance,
    output logic       write_balance_down,

    output logic       dmem_w_valid,
    output word        dmem_w_data,
    output logic [3:0] dmem_w_strobe,

    output logic dmem_ar_valid,
    output word  dmem_ar_address,

    output logic dmem_aw_valid,
    output word  dmem_aw_address,

    input insn_token commit_token,

    input word                             pending_reads_peek[PENDING_FIFO_DEPTH],
    input logic [PENDING_FIFO_DEPTH - 1:0] pending_reads_peek_valid,
    input word                             pending_writes_peek[PENDING_FIFO_DEPTH],
    input logic [PENDING_FIFO_DEPTH - 1:0] pending_writes_peek_valid
);

  localparam int AddrSubwordBits = $clog2($bits(word) / 8);

  word word_address;
  logic is_read, is_write, legal_transaction;
  logic read_stall, write_stall;
  logic commit_waits_for_me;

  assign is_read = ~is_write;
  assign is_write = request.mem_data.direction == MEM_DIRECTION_WRITE;

  assign request_stall = is_write ? write_stall : read_stall;
  assign legal_transaction = valid_i & ~request.misaligned_address & ~request.mem_data.fence;

  assign pending_reads_up = legal_transaction & is_read & ~read_stall;
  assign pending_writes_up = legal_transaction & is_write & ~write_stall;
  assign write_balance_down = pending_writes_up & request.is_memory;

  assign fence_valid = valid_i & request.mem_data.fence;
  assign commit_waits_for_me = request.mem_data.common.token == commit_token;

  assign pending_read_address = word_address;
  assign pending_write_address = word_address;

  always_comb begin
    // Discard address bits [1:0] (AXI forbids non-aligned accesses)
    word_address = request.address;
    word_address[AddrSubwordBits-1:0] = '0;

    ///////////////////////////
    // Read request hazards //
    //////////////////////////

    // RAM/ROM memory reads can execute even before commit expects them,
    // because they have no side effects and cvn be safely discarded later on
    // if necessary. This is unlike I/O reads and all writes, as they can
    // have irreversible side effects (by altering memory or control registers).
    read_stall = ~request.is_memory;

    // Both RAM/ROM and I/O reads are safe to execute if commit is currently
    // waiting for this instruction to complete
    if (commit_waits_for_me) read_stall = 0;

    // Read requests go through dmem.AR, so this channel needs be ready
    if (dmem_ar_stall | pending_reads_stall) read_stall = 1;

    // Reads must wait for any pending writes to the same address to complete.
    // Otherwise, the behavior is unspecified (memory ordering hazard).
    for (int i = 0; i < PENDING_FIFO_DEPTH; ++i) begin
      if (pending_writes_peek_valid[i] & (pending_writes_peek[i] == word_address)) begin
        read_stall = 1;
      end
    end

    ///////////////////////////
    // Write request hazards //
    ///////////////////////////

    // Note: this is a signed comparison, 'write_balance' might be negative
    write_stall = write_balance <= mem_counter'(0);

    // write_balance is meaningful for ordinary memory writes only
    if (~request.is_memory) write_stall = 1;

    if (commit_waits_for_me) write_stall = 0;

    // Write requests go through both dmem.AW and dmem.W, and so the two channels
    // have to be ready for a write to execute
    if (dmem_aw_stall | dmem_w_stall | pending_writes_stall) write_stall = 1;

    // Writes must wait for any pending reads to the same address to complete.
    // Otherwise, the behavior is unspecified (memory ordering hazard).
    for (int i = 0; i < PENDING_FIFO_DEPTH; ++i) begin
      if (pending_reads_peek_valid[i] & (pending_reads_peek[i] == word_address)) begin
        write_stall = 1;
      end
    end


    ////////////////////////////////////////
    // Common read/write abort conditions //
    ///////////////////////////////////////

    // Illegal reads/writes go through the request FIFO as well, but they are
    // discarded and are never sent through dmem
    if (request.misaligned_address) begin
      read_stall  = 0;
      write_stall = 0;
    end

    // A memory fences makes the request unit to wait until the response unit
    // has completed all previous memory transactions
    if (request.mem_data.fence) begin
      read_stall  = ~fence_ready;
      write_stall = ~fence_ready;
    end

    // No further memory reads may start once a flush has been requested.
    // This prevents potential AXI protocol violations.
    if (flush_req) read_stall = 1;

    // After flush req, permit only as many writes as needed to match the commit count
    if (flush_req & (write_balance <= 0)) write_stall = 1;
  end

  always_ff @(posedge clk_core or negedge rst_core_n)
    if (~rst_core_n) begin
      dmem_ar_valid <= 0;
      dmem_aw_valid <= 0;
      dmem_w_valid  <= 0;
    end else begin
      if (~dmem_ar_stall) dmem_ar_valid <= pending_reads_up & ~flush;

      if (~dmem_aw_stall) dmem_aw_valid <= pending_writes_up & ~flush;

      if (~dmem_w_stall) dmem_w_valid <= pending_writes_up & ~flush;
    end

  always_ff @(posedge clk_core) begin
    if (~dmem_ar_stall) dmem_ar_address <= pending_read_address;

    if (~dmem_aw_stall) dmem_aw_address <= pending_write_address;

    if (~dmem_w_stall) begin
      dmem_w_data   <= request.write_data;
      dmem_w_strobe <= request.write_strobe;
    end
  end

endmodule
