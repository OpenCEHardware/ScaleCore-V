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
