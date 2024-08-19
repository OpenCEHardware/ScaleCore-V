module hsv_core_branch
  import hsv_core_pkg::*;
(
    input logic clk_core,
    input logic rst_core_n,

    input  logic flush_req,
    output logic flush_ack,

    // Input Channel (sink) signals
    input  branch_data_t branch_data,
    output logic         in_ready,
    input  logic         in_valid,

    // Output channel (source) signals
    output commit_data_t commit_data,
    input  logic         out_ready,
    output logic         out_valid
);

  logic         stall;

  logic         valid_cond_target;
  branch_data_t branch_data_cond_target;
  logic         taken;
  word          target;

  logic         valid_jump;
  commit_data_t out_jump;

  // First substage
  hsv_core_branch_cond_target sub_cond_target (
      .clk_core,

      .stall,
      .flush_req,

      .in_valid,
      .in_branch_data(branch_data),

      .out_valid(valid_cond_target),
      .out_branch_data(branch_data_cond_target),

      .out_taken(taken),
      .out_target(target)
  );

  // Second substage
  hsv_core_branch_jump sub_jump (
      .clk_core,

      .stall,
      .flush_req,

      .in_valid(valid_cond_target),
      .in_branch_data(branch_data_cond_target),
      .in_taken(taken),
      .in_target(target),

      .out(out_jump),
      .out_valid(valid_jump)
  );

  // Buffering pipe
  hs_skid_buffer #(
      .WIDTH($bits(commit_data))
  ) branch_2_commit (
      .clk_core,
      .rst_core_n,

      .stall,
      .flush_req,

      .in(out_jump),
      .in_ready,
      .in_valid(valid_jump),

      .out(commit_data),
      .out_ready,
      .out_valid
  );

  always_ff @(posedge clk_core or negedge rst_core_n)
    if (~rst_core_n) flush_ack <= 0;
    else flush_ack <= flush_req;

endmodule

module hsv_core_branch_cond_target
  import hsv_core_pkg::*;
(
    input logic clk_core,

    input logic stall,
    input logic flush_req,

    input logic         in_valid,
    input branch_data_t in_branch_data,

    output logic         out_valid,
    output branch_data_t out_branch_data,
    output logic         out_taken,
    output word          out_target
);

  word operand_a, operand_a_flip, operand_b, operand_b_flip, subtract_discarded, target, target_base;
  logic cond_equal, cond_less_than, taken;

  assign operand_a = in_branch_data.common.rs1;
  assign operand_b = in_branch_data.common.rs2;

  assign cond_equal = operand_a == operand_b;
  assign {cond_less_than, subtract_discarded} = {1'b0, operand_a_flip} - {1'b0, operand_b_flip};

  assign target = target_base + in_branch_data.common.immediate;
  assign target_base = in_branch_data.relative ? in_branch_data.common.pc : operand_a;

  always_comb begin
    operand_a_flip = operand_a;
    operand_b_flip = operand_b;

    // Handle signed comparisons by flipping the sign bits. This algorithm is
    // more straightforward here than in the ALU because we don't have to take
    // additions or subtractions into consideration, but comparisons only.
    operand_a_flip[$bits(operand_a_flip)-1] ^= in_branch_data.cond_signed;
    operand_b_flip[$bits(operand_b_flip)-1] ^= in_branch_data.cond_signed;

    unique case (in_branch_data.cond)
      BRANCH_COND_EQUAL:     taken = cond_equal;
      BRANCH_COND_LESS_THAN: taken = cond_less_than;
    endcase

    if (in_branch_data.negate)
      taken = ~taken;

    if (in_branch_data.unconditional)
      taken = 1;
  end

  always_ff @(posedge clk_core) begin
    if (~stall) begin
      out_valid <= in_valid;
      out_branch_data <= in_branch_data;

      out_taken <= taken;
      out_target <= target;
    end

    if (flush_req) out_valid <= 0;
  end

endmodule

module hsv_core_branch_jump
  import hsv_core_pkg::*;
(
    input logic clk_core,

    input logic stall,
    input logic flush_req,

    input logic         in_valid,
    input branch_data_t in_branch_data,
    input logic         in_taken,
    input word          in_target,

    output logic         out_valid,
    output commit_data_t out
);

  word final_pc;
  logic alignment_exception, mispredict;

  assign final_pc = in_taken ? in_target : in_branch_data.common.pc_increment;
  assign mispredict = final_pc != in_branch_data.predicted;

  // Trap if target address is not aligned to a 4-byte boundary
  assign alignment_exception = in_taken & (in_target[$bits(word) - $bits(pc_ptr) - 1:0] != '0);

  always_ff @(posedge clk_core) begin
    if (~stall) begin
      out_valid <= in_valid;

      out.jump <= mispredict;
      out.trap <= alignment_exception;
      out.common <= in_branch_data.common;
      out.result <= in_branch_data.common.pc_increment;
      out.next_pc <= final_pc;
      out.writeback <= in_branch_data.link;
    end

    if (flush_req) out_valid <= 0;
  end

endmodule
