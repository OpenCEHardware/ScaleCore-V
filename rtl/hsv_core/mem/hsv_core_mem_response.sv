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

    output logic fence_ready,
    input  logic fence_valid,
    output logic pending_reads_down,
    output logic pending_writes_down,
    output logic write_balance_up,

    input mem_counter pending_reads,
    input mem_counter pending_writes,
    input word        pending_write_completed_address,

    input  logic      dmem_r_valid,
    input  word       dmem_r_data,
    input  axi_resp_t dmem_r_resp,
    output logic      dmem_r_ready,

    input  logic      dmem_b_valid,
    input  axi_resp_t dmem_b_resp,
    output logic      dmem_b_ready,

    output commit_data_t out,
    output logic         valid_o,

    input logic commit_mem
);

  word extend_mask, read_data;
  logic completed, is_read, is_write, sign_bit;
  logic [1:0] read_shift;

  word delayed_write_error_address, exception_address;
  exception_t exception_cause;
  commit_action_t action;

  logic
      delayed_write_error, dmem_b_error, dmem_r_error, io_error, imprecise_write_error, misaligned;

  logic writes_to_commit_up, writes_to_commit_down;
  logic discard_responses_up, discard_responses_down;
  mem_counter writes_to_commit, discard_responses;

  assign is_read = ~is_write;
  assign is_write = response.mem_data.direction == MEM_DIRECTION_WRITE;
  assign misaligned = response.misaligned_address;

  assign write_balance_up = commit_mem & (writes_to_commit != '0);
  assign pending_reads_down = dmem_r_ready & dmem_r_valid;
  assign pending_writes_down = dmem_b_ready & dmem_b_valid;

  assign writes_to_commit_up = completed & is_write & response.is_memory & ~commit_stall;
  assign writes_to_commit_down = write_balance_up;

  assign discard_responses_up = write_balance_up;
  assign discard_responses_down = pending_writes_down & (discard_responses != '0);

  assign response_stall = commit_stall | ~completed;

  assign read_shift = response.address[$bits(read_shift)-1:0];

  assign dmem_b_error = is_axi_error(dmem_b_resp);
  assign dmem_r_error = is_axi_error(dmem_r_resp);

  assign imprecise_write_error = pending_writes_down & dmem_b_error & address_is_memory(
      pending_write_completed_address
  );

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

    exception_address = response.address;

    // The request module never executes misaligned address operations,
    // they are pushed on until they reach here and an exception is committed
    if (~valid_i | commit_stall | misaligned) begin
      dmem_r_ready = 0;
      dmem_b_ready = 0;
    end

    // Discard responses to ordinary memory writes
    if (discard_responses != '0) dmem_b_ready = 1;

    if (is_read) begin
      // Commit reads as soon as the read response is available
      io_error  = dmem_r_error;
      completed = dmem_r_valid;
    end else if (response.is_memory) begin
      // Commit memory writes as soon as possible. Note that I/O errors from
      // ordinary memory writes trigger so-called "imprecise exceptions". That
      // is, the exception will be taken on by some future "victim"
      // instruction that happens to also be an ordinary memory write. The
      // mtval CSR will always hold the correct faulting address. This is an
      // unfortunate consequence of our current memory unit architecture and
      // guaranteeing precise store access exceptions would likely require
      // some kind of out-of-order approach. This behavior is visible to
      // M-mode software.
      io_error = delayed_write_error;
      completed = 1;
      exception_address = delayed_write_error_address;
    end else begin
      // Commit I/O writes as soon as the write response is available
      io_error  = dmem_b_error;
      completed = dmem_b_valid & (discard_responses == '0);
    end

    fence_ready = 0;
    if (response.mem_data.fence) begin
      io_error = 0;
      completed = fence_valid & (pending_reads == '0) & (pending_writes == '0);
      fence_ready = completed & ~commit_stall;
    end

    if (~valid_i) completed = 0;

    // Shift by 0, 8, 16 or 24 bits to retrieve the addressed subword
    read_data = dmem_r_data >> (5'd8 * 5'(read_shift));

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

    if (is_read) exception_cause = misaligned ? EXC_LOAD_ADDRESS_MISALIGNED : EXC_LOAD_ACCESS_FAULT;
    else exception_cause = misaligned ? EXC_STORE_ADDRESS_MISALIGNED : EXC_STORE_ACCESS_FAULT;

    if (io_error | misaligned) action = COMMIT_EXCEPTION;
    else action = COMMIT_NEXT;

    if (response.mem_data.fence) action = COMMIT_NEXT;
  end

  always_ff @(posedge clk_core) begin
    if (~commit_stall) begin
      valid_o <= completed;

      out.action <= action;
      out.common <= response.mem_data.common;
      out.result <= read_data;
      out.next_pc <= response.mem_data.common.pc_increment;
      out.writeback <= is_read;
      out.exception_cause <= exception_cause;
      out.exception_value <= exception_address;
    end

    if (~delayed_write_error & imprecise_write_error) begin
      delayed_write_error <= 1;
      delayed_write_error_address <= pending_write_completed_address;
    end

    if (flush) begin
      valid_o <= 0;
      delayed_write_error <= 0;
    end
  end

endmodule
