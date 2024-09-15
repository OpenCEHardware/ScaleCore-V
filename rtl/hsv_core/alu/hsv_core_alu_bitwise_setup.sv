module hsv_core_alu_bitwise_setup
  import hsv_core_pkg::*;
(
    input logic clk_core,

    input logic stall,
    input logic flush_req,

    input logic      valid_i,
    input alu_data_t in_alu_data,

    output logic      valid_o,
    output alu_data_t out_alu_data,
    output word       out_shift_lo,
    output word       out_shift_hi,
    output shift      out_shift_count,
    output adder_in   out_adder_a,
    output adder_in   out_adder_b
);

  word operand_a, operand_b;
  logic operand_b_non_zero, shift_left;
  adder_in operand_a_ext, operand_a_flip, operand_b_ext, operand_b_flip, operand_b_neg;

  // Left-shifts by zero is an edge case. We convert them to right-shifts by
  // zero. Try to follow on what would happen if it were not checked for.
  // Regarding operand_b_neg and out_shift_count below, note that -0 = 0.
  assign shift_left = in_alu_data.negate & (operand_b[4:0] != '0);

  // Sign-extend to 33 bits for adder
  assign operand_a_ext = {operand_a[$bits(operand_a)-1], operand_a};
  assign operand_b_ext = {operand_b[$bits(operand_b)-1], operand_b};

  assign operand_b_neg = in_alu_data.negate ? -operand_b_ext : operand_b_ext;
  assign operand_b_non_zero = operand_b != '0;

  always_comb begin
    // Extract read registers from the in_alu_data struct
    operand_a = in_alu_data.common.rs1;

    if (in_alu_data.is_immediate) operand_b = in_alu_data.common.immediate;
    else operand_b = in_alu_data.common.rs2;

    // Conditionally converts from two's complement to excess-2^31 (offset
    // binary). This makes it trivial to compare signed integers, at the
    // cost of breaking two's complement math.
    //
    // 8-bit example:
    //
    // | Binary value | Excess-128 | Unsigned representation |
    // | 00000000     | -128       | 0                       |
    // | 00000001     | -127       | 1                       |
    // | ...          | ...        | ...                     |
    // | 01111111     | -1         | 127                     |
    // | 10000000     | 0          | 128                     |
    // | 10000001     | 1          | 129                     |
    // | ...          | ...        | ...                     |
    // | 11111111     | 127        | 255                     |
    //
    // We need to extend with an additional 33th bit in order prevent adder
    // overflows from affecting results. Remember that, at this point,
    // operand_b has already been negated (comparison is implemented as
    // a subtraction).
    operand_a_flip = operand_a_ext;
    operand_b_flip = operand_b_neg;

    if (in_alu_data.flip_signs) begin
      // slt (signed): flip the 33th bit to make unsigned comparisons work
      operand_a_flip[$bits(operand_a_flip)-1] = ~operand_a_flip[$bits(operand_a_flip)-1];
      operand_b_flip[$bits(operand_b_flip)-1] = ~operand_b_flip[$bits(operand_b_flip)-1];
    end else begin
      // sltu (unsigned)
      // a is zero or positive (sign = 0)
      // b is zero or negative (sign depends on whether it's zero)
      //
      // Rationale: q = (+a) + (-b)
      operand_a_flip[$bits(operand_a_flip)-1] = 0;
      operand_b_flip[$bits(operand_b_flip)-1] = operand_b_non_zero;
    end
  end

  always_ff @(posedge clk_core) begin
    if (~stall) begin
      valid_o <= valid_i;
      out_alu_data <= in_alu_data;

      unique case (in_alu_data.bitwise_select)
        ALU_BITWISE_AND:  out_shift_lo <= operand_a & operand_b;
        ALU_BITWISE_OR:   out_shift_lo <= operand_a | operand_b;
        ALU_BITWISE_XOR:  out_shift_lo <= operand_a ^ operand_b;
        ALU_BITWISE_PASS: out_shift_lo <= shift_left ? '0 : operand_a;
        default:          out_shift_lo <= 'x;
      endcase

      if (shift_left) out_shift_hi <= operand_a;
      else
        out_shift_hi <= {($bits(word)) {in_alu_data.sign_extend & operand_a[$bits(operand_a)-1]}};

      // According to RISC-V spec, higher bits in the shift count must
      // be silently discarded. Only shift if ALU_BITWISE_PASS
      unique case (in_alu_data.bitwise_select)
        ALU_BITWISE_PASS: out_shift_count <= operand_b_neg[$bits(out_shift_count)-1:0];
        default:          out_shift_count <= '0;
      endcase

      out_adder_a <= operand_a_flip;
      out_adder_b <= operand_b_flip;

      // auipc: add immediate (b) to program counter
      // The 33th bit is ignored in this case, so we set it to 0
      if (in_alu_data.pc_relative) out_adder_a <= {1'b0, in_alu_data.common.pc};
    end

    if (flush_req) valid_o <= 0;
  end

endmodule
