
//TODO
module hsv_core_alu
(
    input logic clk_core,
    input logic rst_core_n,

    input logic  flush_req,
    output logic flush_ack,

	// Comming from/to last pipe
output logic      in_ready,
input logic          in_valid,
    input issue2alu_t in_op,
input word_t      in_read_rs2, //TODO esto para common
    input word_t      in_read_rs1, //TODO esto para common
   
	// Going to/from next pipe
    input logic          out_ready,
    output logic         out_valid,
    output exec2commit_t     out_op

);

	logic stall;
    hs_skid_buffer exec_2_commit(
		.clk_core,
		   .rst_core_n,

		.stall,
		.flush_req,

		.in_ready,
		.in_valid,
		
		.out_ready
		      .out_valid,
		);




    hsv_core_alu_bitwise_setup bloque_1();
    hsv_core_alu_shift_add bloque_2();



endmodule

module hsv_core_alu_bitwise_setup
  import hsv_core_pkg::*;
(
    input logic clk,

    input logic stall,
    input logic flush_req,

    input logic       in_valid,
    input issue2alu_t in_op,
    input word_t      in_read_rs1,
    input word_t      in_read_rs2,

    output logic       out_valid,
    output issue2alu_t out_op,
    output word_t      out_shift_lo,
    output word_t      out_shift_hi,
    output shift_t     out_shift_count,
    output word_t      out_adder_a,
    output word_t      out_adder_b
);

  logic shift_left;
  word_t operand_a_flip, operand_b, operand_b_flip, operand_b_neg;

  // Left-shifts by zero is an edge case. We convert them to right-shifts by
  // zero. Try to follow on what would happen if it were not checked for.
  // Regarding operand_b_neg and out_shift_count below, note that -0 = 0.
  assign shift_left = in_op.negate & (operand_b != '0);

  assign operand_b = in_op.is_immediate ? in_op.common.immediate : in_read_rs2;
  assign operand_b_neg = in_op.negate ? -operand_b : operand_b;

  always_comb begin
    operand_a_flip = in_read_rs1;
    operand_b_flip = operand_b_neg;

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
    operand_a_flip[$bits(operand_a_flip)-1] ^= in_op.flip_signs;
    operand_b_flip[$bits(operand_b_flip)-1] ^= in_op.flip_signs;
  end

  always_ff @(posedge clk) begin
    if (~stall) begin
      out_op <= in_op;
      out_valid <= in_valid;

      unique case (in_op.bitwise_select)
        ALU_BITWISE_AND:  out_shift_lo <= in_read_rs1 & operand_b;
        ALU_BITWISE_OR:   out_shift_lo <= in_read_rs1 | operand_b;
        ALU_BITWISE_XOR:  out_shift_lo <= in_read_rs1 ^ operand_b;
        ALU_BITWISE_PASS: out_shift_lo <= shift_left ? '0 : in_read_rs1;
      endcase

      if (shift_left) out_shift_hi <= in_read_rs1;
      else
        out_shift_hi <= {($bits(word_t)) {in_op.sign_extend & in_read_rs1[$bits(in_read_rs1)-1]}};

      // According to RISC-V spec, higher bits in the shift count must
      // be silently discarded
      out_shift_count <= operand_b_neg[$bits(out_shift_count)-1];

      out_adder_a <= in_op.pc_relative ? in_op.common.pc : operand_a_flip;
      out_adder_b <= operand_b_flip;
    end

    if (flush_req) out_valid <= 0;
  end

endmodule

module hsv_core_alu_shift_add
  import hsv_core_pkg::*;
(
    input logic clk,

    input logic stall,
    input logic flush_req,

    input logic       in_valid,
    input issue2alu_t in_op,
    input word_t      in_shift_lo,
    input word_t      in_shift_hi,
    input shift_t     in_shift_count,
    input word_t      in_adder_a,
    input word_t      in_adder_b,

    output logic       out_valid,
    output issue2alu_t out_op,
    output word_t      out_q
);

  logic adder_carry;
  word_t adder_q, shift_q, shift_discarded;

  assign {shift_discarded, shift_q} = {in_shift_hi, in_shift_lo} >> in_shift_count;

  always_comb begin
    // slt/slti/sltiu/sltu: set rd to 0 or 1 (zero-extended to XLEN)
    // depending on src1 < src2. Signed comparisons are mapped to unsigned
    // equivalents by the previous bitwise/setup ALU substage. In order to
    // implement unsigned comparisons we may note the following:
    //
    //     src1 < src2
    // <=> src1 - src2 < 0
    // <=> (+src1) + (-src2) < 0
    //
    // As src1, src2 >= 0 (they are unsigned), we can extend both to
    // equivalent signed versions by introduce a 33rd bit to each operand
    // before adding. We don't have to negate src2: that has already been
    // done by the previous substage. Then, the adder output's extra bit
    // is the comparison's result. Since less-than is the only ALU
    // comparison operator required by the RISC-V base, and this whole
    // extra bit business won't interfere with the lower 32 bits in any
    // manner, we simply hard-code the input sign bits to 0/+ and 1/-,
    // respectively.
    {adder_carry, adder_q} = {1'b0, in_adder_a} + {1'b1, in_adder_b};
    if (in_op.compare) adder_q = word_t'(adder_carry);
  end

  always_ff @(posedge clk) begin
    if (~stall) begin
      out_op <= in_op;
      out_valid <= in_valid;

      unique case (in_op.out_select)
        ALU_OUT_ADDER: out_q <= adder_q;
        ALU_OUT_SHIFT: out_q <= shift_q;
      endcase
    end

    if (flush_req) out_valid <= 0;
  end

endmodule
