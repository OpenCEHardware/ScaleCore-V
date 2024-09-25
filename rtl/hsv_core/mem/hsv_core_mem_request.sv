module hsv_core_mem_request
  import hsv_core_pkg::*;
(
    input logic clk_core,
    input logic rst_core_n,

    input  logic flush,
    input  logic dmem_w_stall,
    input  logic dmem_ar_stall,
    input  logic dmem_aw_stall,
    output logic request_stall,

    input read_write_t request,
    input logic        valid_i,

    input  logic       fence_ready,
    output logic       fence_valid,
    input  mem_counter pending_reads,
    output logic       pending_reads_up,
    input  mem_counter pending_writes,
    output logic       pending_writes_up,
    input  mem_counter write_balance,
    output logic       write_balance_down,

    output logic       dmem_w_valid,
    output word        dmem_w_data,
    output logic [3:0] dmem_w_strobe,

    output logic dmem_ar_valid,
    output word  dmem_ar_address,

    output logic dmem_aw_valid,
    output word  dmem_aw_address,

    input insn_token commit_token
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

  always_comb begin
    // RAM/ROM memory reads can execute even before commit expects them,
    // because they have no side effects and cvn be safely discarded later on
    // if necessary. This is unlike I/O reads and all writes, as they can
    // have irreversible side effects (by altering memory or control registers).
    read_stall = ~request.is_memory;

    // Both RAM/ROM and I/O reads are safe to execute if commit is currently
    // waiting for this instruction to complete
    if (commit_waits_for_me) read_stall = 0;

    // Read requests go through dmem.AR, so this channel needs be ready
    if (dmem_ar_stall) read_stall = 1;

    // Reads cannot proceed unless all previous writes have completed
    if (pending_writes != '0) read_stall = 1;

    // Note: this is a signed comparison (counter may be negative)
    write_stall = write_balance <= mem_counter'(0);

    // write_balance is meaningful for ordinary memory writes only
    if (~request.is_memory) write_stall = 1;

    if (commit_waits_for_me) write_stall = 0;

    // Write requests go through both dmem.AW and dmem.W, and so the two channels
    // have to be ready for a write to execute
    if (dmem_aw_stall | dmem_w_stall) write_stall = 1;

    // Writes cannot proceed unless all previous reads have completed
    if (pending_reads != '0) write_stall = 1;

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

    // Discard address bits [1:0], AXI transactions must be word-aligned
    word_address = request.address;
    word_address[AddrSubwordBits-1:0] = '0;
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
    if (~dmem_ar_stall) dmem_ar_address <= word_address;

    if (~dmem_aw_stall) dmem_aw_address <= word_address;

    if (~dmem_w_stall) begin
      dmem_w_data   <= request.write_data;
      dmem_w_strobe <= request.write_strobe;
    end
  end

endmodule
