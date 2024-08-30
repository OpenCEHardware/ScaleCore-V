module hsv_core_mem
  import hsv_core_pkg::*;
#(
    int FIFO_DEPTH = 8
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

    axil_if.m dmem
);

  logic dmem_ar_stall, dmem_aw_stall, dmem_w_stall;
  read_write_t transaction, request_fifo_out, response_fifo_out;

  logic request_fifo_in_ready, request_fifo_in_valid, request_fifo_in_stall;
  logic request_fifo_out_ready, request_fifo_out_valid, request_fifo_out_stall;

  logic response_fifo_in_ready, response_fifo_in_valid, response_fifo_in_stall;
  logic response_fifo_out_ready, response_fifo_out_valid, response_fifo_out_stall;

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

  logic commit_stall, out_valid;
  commit_data_t out_response;

  // Flush occurs after all pending reads and writes have completed
  logic flush, can_flush;
  assign can_flush = (pending_reads == '0) & (pending_writes == '0) & (write_balance == '0);

  assign ready_o = ~request_fifo_in_stall & ~response_fifo_in_stall;

  assign request_fifo_in_stall = ~request_fifo_in_ready & request_fifo_in_valid;
  assign request_fifo_out_ready = ~request_fifo_out_stall;

  assign response_fifo_in_stall = ~response_fifo_in_ready & response_fifo_in_valid;
  assign response_fifo_out_ready = ~response_fifo_out_stall;

  assign dmem_w_stall = ~dmem.wready & dmem.wvalid;
  assign dmem_ar_stall = ~dmem.arready & dmem.arvalid;
  assign dmem_aw_stall = ~dmem.awready & dmem.awvalid;

  hsv_core_mem_address address_stage (
      .clk_core,

      .flush,
      .request_stall (request_fifo_in_stall),
      .response_stall(response_fifo_in_stall),

      .mem_data,
      .valid_i,

      .transaction,
      .request_valid_o (request_fifo_in_valid),
      .response_valid_o(response_fifo_in_valid)
  );

  hs_fifo #(
      .WIDTH($bits(read_write_t)),
      .DEPTH(FIFO_DEPTH)
  ) request_fifo (
      .clk_core,
      .rst_core_n,

      .flush,

      .in(transaction),
      .ready_o(request_fifo_in_ready),
      .valid_i(request_fifo_in_valid),

      .out(request_fifo_out),
      .ready_i(request_fifo_out_ready),
      .valid_o(request_fifo_out_valid)
  );

  hsv_core_mem_request request_stage (
      .clk_core,
      .rst_core_n,

      .flush,
      .dmem_w_stall,
      .dmem_ar_stall,
      .dmem_aw_stall,
      .request_stall(request_fifo_out_stall),

      .request(request_fifo_out),
      .valid_i(request_fifo_out_valid),

      .pending_reads,
      .pending_reads_up,
      .pending_writes,
      .pending_writes_up,
      .write_balance,
      .write_balance_down,

      .dmem_w_valid (dmem.wvalid),
      .dmem_w_data  (dmem.wdata),
      .dmem_w_strobe(dmem.wstrb),

      .dmem_ar_valid  (dmem.arvalid),
      .dmem_ar_address(dmem.araddr),

      .dmem_aw_valid  (dmem.awvalid),
      .dmem_aw_address(dmem.awaddr),

      .commit_token
  );

  hs_fifo #(
      .WIDTH($bits(read_write_t)),
      .DEPTH(FIFO_DEPTH)
  ) response_fifo (
      .clk_core,
      .rst_core_n,

      .flush,

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

      .flush,
      .commit_stall,
      .response_stall(response_fifo_out_stall),

      .response(response_fifo_out),
      .valid_i (response_fifo_out_valid),

      .pending_reads_down,
      .pending_writes_down,
      .write_balance_up,

      .dmem_r_valid(dmem.rvalid),
      .dmem_r_data (dmem.rdata),
      .dmem_r_resp (dmem.rresp),
      .dmem_r_ready(dmem.rready),

      .dmem_b_valid(dmem.bvalid),
      .dmem_b_resp (dmem.bresp),
      .dmem_b_ready(dmem.bready),

      .commit_mem,

      .out(out_response),
      .valid_o(out_valid)
  );

  hs_skid_buffer #(
      .WIDTH($bits(commit_data))
  ) mem_2_commit (
      .clk_core,
      .rst_core_n,

      .stall(commit_stall),
      .flush_req,

      .in(out_response),
      .ready_o(),  // .stall is enough for this execution unit
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
      .flush,

      .value(pending_reads)
  );

  hsv_core_mem_counter pending_writes_counter (
      .clk_core,
      .rst_core_n,

      .up  (pending_writes_up),
      .down(pending_writes_down),
      .flush,

      .value(pending_writes)
  );

  hsv_core_mem_counter write_balance_counter (
      .clk_core,
      .rst_core_n,

      .up  (write_balance_up),
      .down(write_balance_down),
      .flush,

      .value(write_balance)
  );

  always_ff @(posedge clk_core or negedge rst_core_n)
    if (~rst_core_n) begin
      flush <= 1;
      flush_ack <= 1;
    end else begin
      flush <= flush_req & can_flush;
      flush_ack <= flush;
    end

endmodule

module hsv_core_mem_address
  import hsv_core_pkg::*;
(
    input logic clk_core,

    input logic flush,
    input logic request_stall,
    input logic response_stall,

    input mem_data_t mem_data,
    input logic      valid_i,

    output read_write_t transaction,
    output logic        request_valid_o,
    output logic        response_valid_o
);

  localparam int AddrSubwordBits = $clog2($bits(word) / 8);
  localparam int AddrSubhalfBits = AddrSubwordBits - 1;

  word address, write_data, write_data_word;
  logic unaligned_address;
  logic [3:0] write_strobe;
  logic [7:0] write_data_byte;
  logic [15:0] write_data_half;
  logic [AddrSubwordBits - 1:0] read_shift;

  assign write_data_byte = write_data_word[$bits(write_data_byte)-1:0];
  assign write_data_half = write_data_word[$bits(write_data_half)-1:0];
  assign write_data_word = mem_data.common.rs2;

  always_comb begin
    // Note that rs1 is always the base address, even for stores:
    // lw rd,  imm(rs1)
    // sw rs2, imm(rs1)
    address = mem_data.common.rs1 + mem_data.common.immediate;

    // AXI requires all accesses to be word-sized and word-aligned. However,
    // RISC-V permits loads and stores to individual bytes and half-words
    // (lb/lh, sb/sh). Therefore, we map these instructions into
    // equivalent word accesses. For writes, AXI's wstrb signal (write
    // strobe) is used to indicate which of the 4 bytes in a word are
    // actually written. We simply repeat the datum as many times as needed
    // to fill a word and then set the strobe appropriately (see below).
    //
    // For reads, it is sufficient to request the whole word and select
    // whatever part of it we really need. The read data word is
    // right-shifted and either sign-extended or zero-extended (lh/lb vs
    // lhu/lbu).
    //
    // In both cases, the lower address bits select the correct shifts
    // and/or masks. We also need to raise traps if an unaligned access is
    // attempted, and this is also done by checking the lower bits.
    //
    // For words (datum 'x' is 32 bits wide):
    // - Written word is x.
    // - Write strobe mask is always 4'b1111 because all bytes are written.
    // - Read word remains as-is
    // - Alignment trap if address bits [1:0] != 2'b00.
    //
    // For half-words (datum 'x' is 16 bits wide):
    // - Written word is {x, x}
    // - Write strobe mask is either 4'b0011 or 4'b1100, depending on
    //    address bit [1].
    // - Read selects either bits [15:0] or bits [31:16] from read word
    // - Alignment trap if bit [0] != 1'b0.
    //
    // For bytes (datum 'x' is 8 bits wide)
    // - Written word is {x, x, x, x}.
    // - Write strobe mask is one of 4'b0001, 4'b0010, 4'b0100, 4'b1000,
    //   depending on address bits [1:0].
    // - Read selects one of [7:0], [15:8], [23:16] or [31:24].
    // - Alignment traps never happen since any address is aligned to 1 byte.

    unique case (mem_data.size)
      MEM_SIZE_WORD: begin
        write_data = write_data_word;
        write_strobe = 4'b1111;
        unaligned_address = address[AddrSubwordBits-1:0] != '0;
      end

      MEM_SIZE_HALF: begin
        write_data = {2{write_data_half}};

        unique case (address[AddrSubwordBits-1:AddrSubhalfBits])
          1'b0:    write_strobe = 4'b0011;
          1'b1:    write_strobe = 4'b1100;
          default: write_strobe = 'x;
        endcase

        unaligned_address = address[AddrSubhalfBits-1:0] != '0;
      end

      MEM_SIZE_BYTE: begin
        write_data = {4{write_data_byte}};

        unique case (address[AddrSubwordBits-1:0])
          2'b00:   write_strobe = 4'b0001;
          2'b01:   write_strobe = 4'b0010;
          2'b10:   write_strobe = 4'b0100;
          2'b11:   write_strobe = 4'b1000;
          default: write_strobe = 'x;
        endcase

        unaligned_address = 1'b0;
      end

      default: begin
        write_data = 'x;
        write_strobe = 'x;
        unaligned_address = 'x;
      end
    endcase

    // Read results are right-shifted during the response stage in
    // accordance with the position of the requested byte or half-word
    // within the read word. Note that this is a numer of bytes, not bits.
    read_shift = address[AddrSubwordBits-1:0];

    // Finally, zero-out the lower bits as we don't need them anymore. This
    // `address` has now become the actual address the CPU core will send
    // through dmem to the interconnect.
    address[AddrSubwordBits-1:0] = '0;
  end

  always_ff @(posedge clk_core) begin
    if (~request_stall) request_valid_o <= valid_i & ~response_stall;

    if (~response_stall) response_valid_o <= valid_i & ~request_stall;

    if (~request_stall & ~response_stall) begin
      transaction.address <= address;
      transaction.mem_data <= mem_data;
      transaction.is_memory <= address_is_memory(address);
      transaction.read_shift <= read_shift;
      transaction.write_data <= write_data;
      transaction.write_strobe <= write_strobe;
      transaction.unaligned_address <= unaligned_address;
    end

    if (flush) begin
      request_valid_o  <= 0;
      response_valid_o <= 0;
    end
  end

endmodule

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

  logic is_read, is_write, legal_transaction;
  logic read_stall, write_stall;
  logic commit_waits_for_me;

  assign is_read = ~is_write;
  assign is_write = request.mem_data.direction == MEM_DIRECTION_WRITE;

  assign request_stall = is_write ? write_stall : read_stall;
  assign legal_transaction = valid_i & ~request.unaligned_address;

  assign pending_reads_up = legal_transaction & is_read & ~read_stall;
  assign pending_writes_up = legal_transaction & is_write & ~write_stall;
  assign write_balance_down = pending_writes_up & request.is_memory;

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

    // Illegal reads go through the request FIFO as well, but they are
    // discarded and are never sent through dmem
    if (request.unaligned_address) read_stall = 0;

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

    // Illegal writes go through the request FIFO as well, but they are
    // discarded and are never sent through dmem
    if (request.unaligned_address) write_stall = 0;
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
    if (~dmem_ar_stall) dmem_ar_address <= request.address;

    if (~dmem_aw_stall) dmem_aw_address <= request.address;

    if (~dmem_w_stall) begin
      dmem_w_data   <= request.write_data;
      dmem_w_strobe <= request.write_strobe;
    end
  end

endmodule

module hsv_core_mem_response
  import hsv_core_pkg::*;
(
    input logic clk_core,
    input logic rst_core_n,

    input  logic flush,
    input  logic commit_stall,
    output logic response_stall,

    input read_write_t response,
    input logic        valid_i,

    output logic pending_reads_down,
    output logic pending_writes_down,
    output logic write_balance_up,

    input  logic      dmem_r_valid,
    input  word       dmem_r_data,
    input  axi_resp_t dmem_r_resp,
    output logic      dmem_r_ready,

    input  logic      dmem_b_valid,
    input  axi_resp_t dmem_b_resp,
    output logic      dmem_b_ready,

    input logic commit_mem,

    output commit_data_t out,
    output logic         valid_o
);

  word extend_mask, read_data;
  logic completed, error, is_read, is_write, sign_bit;

  logic writes_to_commit_up, writes_to_commit_down;
  logic discard_responses_up, discard_responses_down;
  mem_counter writes_to_commit, discard_responses;

  assign is_read = ~is_write;
  assign is_write = response.mem_data.direction == MEM_DIRECTION_WRITE;

  assign write_balance_up = commit_mem & (writes_to_commit != '0);
  assign pending_reads_down = dmem_r_ready & dmem_r_valid;
  assign pending_writes_down = dmem_b_ready & dmem_b_valid;

  assign writes_to_commit_up = completed & is_write & response.is_memory & ~commit_stall;
  assign writes_to_commit_down = write_balance_up;

  assign discard_responses_up = write_balance_up;
  assign discard_responses_down = pending_writes_down;

  assign response_stall = commit_stall | ~completed;

  hsv_core_mem_counter writes_to_commit_counter (
      .clk_core,
      .rst_core_n,

      .up  (writes_to_commit_up),
      .down(writes_to_commit_down),
      .flush,

      .value(writes_to_commit)
  );

  hsv_core_mem_counter discard_responses_counter (
      .clk_core,
      .rst_core_n,

      .up  (discard_responses_up),
      .down(discard_responses_down),
      .flush,

      .value(discard_responses)
  );

  always_comb begin
    dmem_r_ready = is_read;
    dmem_b_ready = is_write;

    // The request module never executes unaligned address operations,
    // they are pushed on until they reach here and an exception is committed
    if (~valid_i | commit_stall | response.unaligned_address) begin
      dmem_r_ready = 0;
      dmem_b_ready = 0;
    end

    // Discard responses to ordinary memory writes
    if (discard_responses != '0) dmem_b_ready = 1;

    if (is_read) begin
      // Commit reads as soon as the read response is available
      completed = dmem_r_valid;
      error = is_axi_error(dmem_r_resp);
    end else if (response.is_memory) begin
      // Commit memory writes as soon as possible
      // FIXME: Memory write errors are silently ignored!
      completed = 1;
      error = 0;
    end else begin
      // Commit I/O writes as soon as the write response is available
      completed = dmem_b_valid & (discard_responses == '0);
      error = is_axi_error(dmem_b_resp);
    end

    if (~valid_i) completed = 0;

    // Shift by 0, 8, 16 or 24 bits to retrieve the addressed subword
    read_data = dmem_r_data >> (8 * response.read_shift);

    unique case (response.mem_data.size)
      MEM_SIZE_WORD: begin
        sign_bit = read_data[31];
        extend_mask = word'('1) << 32;
      end

      MEM_SIZE_HALF: begin
        sign_bit = read_data[15];
        extend_mask = word'('1) << 16;
      end

      MEM_SIZE_BYTE: begin
        sign_bit = read_data[7];
        extend_mask = word'('1) << 8;
      end

      // Undefined
      default: begin
        sign_bit = 'x;
        extend_mask = 'x;
      end
    endcase

    // Sign-extend with 1's only if the operation is a sign-extended load
    // (lb/lh) and the read datum's sign bit is 1. Otherwise, clear the
    // higher bits in order to zero-extend the result.
    //
    // E.g. a byte load (lb) sets bits [31:8] to all-ones or all-zeros.
    if (response.mem_data.sign_extend & sign_bit) read_data |= extend_mask;
    else read_data &= ~extend_mask;
  end

  always_ff @(posedge clk_core) begin
    if (~commit_stall) begin
      valid_o <= completed;

      out.jump <= 0;
      out.trap <= error | response.unaligned_address;
      out.common <= response.mem_data.common;
      out.result <= read_data;
      out.next_pc <= response.mem_data.common.pc_increment;
      out.writeback <= is_read;
    end

    if (flush) valid_o <= 0;
  end

endmodule

module hsv_core_mem_counter
  import hsv_core_pkg::*;
(
    input logic clk_core,
    input logic rst_core_n,

    input logic up,
    input logic down,
    input logic flush,

    output mem_counter value
);

  always_ff @(posedge clk_core or negedge rst_core_n)
    if (~rst_core_n) value <= '0;
    else begin
      // Preserve the value if both up & down (they cancel each other)

      if (up & ~down) value <= value + 1;
      else if (~up & down) value <= value - 1;

      if (flush) value <= '0;
    end

endmodule
