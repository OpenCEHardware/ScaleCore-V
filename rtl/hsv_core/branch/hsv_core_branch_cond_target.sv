module hsv_core_branch_cond_target
  import hsv_core_pkg::*;
(
    input logic clk_core,

    input logic stall,
    input logic flush_req,

    input logic         valid_i,
    input branch_data_t in_branch_data,

    output logic         valid_o,
    output branch_data_t out_branch_data,
    output logic         out_taken,
    output word          out_target
);

  word
      operand_a, operand_a_flip, operand_b, operand_b_flip, subtract_discarded, target, target_base;
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
      default:               taken = 'x;
    endcase

    if (in_branch_data.negate) taken = ~taken;

    if (in_branch_data.unconditional) taken = 1;
  end

  always_ff @(posedge clk_core) begin
    if (~stall) begin
      valid_o <= valid_i;
      out_branch_data <= in_branch_data;

      out_taken <= taken;
      out_target <= target;
    end

    if (flush_req) valid_o <= 0;
  end

endmodule
