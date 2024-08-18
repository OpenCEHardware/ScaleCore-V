module hsv_core_alu
  import hsv_core_pkg::*;
(

    // Sequential signals
    input logic clk_core,
    input logic rst_core,

    // Flush signals
    input  logic flush_req,
    output logic flush_ack,

    // Input Channel (sink) signals
    input alu_data_t alu_data,
    output logic in_ready,
    input logic in_valid,

    // Output (source) signals
    output commit_data_t commit_data,
    input logic out_ready,
    output logic out_valid
);

  logic         stall;

  logic         valid_setup;
  alu_data_t    alu_data_setup;

  word          shift_lo;
  word          shift_hi;
  shift         shift_count;
  word          adder_a;
  word          adder_b;

  logic         valid_shift_add;
  alu_data_t    alu_data_shift_add;
  word          q_shift_add;

  commit_data_t commit_data_temp;

  // First Stage
  hsv_core_alu_bitwise_setup setup (
      .clk_core,

      .stall,
      .flush_req,

      .in_valid,
      .in_alu_data(alu_data),

      .out_valid(valid_setup),
      .out_alu_data(alu_data_setup),

      .out_shift_lo(shift_lo),
      .out_shift_hi(shift_hi),
      .out_shift_count(shift_count),
      .out_adder_a(adder_a),
      .out_adder_b(adder_b)
  );

  // Second Stage
  hsv_core_alu_shift_add shift_add (
      .clk_core,

      .stall,
      .flush_req,

      .in_valid(valid_setup),
      .in_alu_data(alu_data_setup),
      .in_shift_lo(shift_lo),
      .in_shift_hi(shift_hi),
      .in_shift_count(shift_count),
      .in_adder_a(adder_a),
      .in_adder_b(adder_b),

      .out_valid(valid_shift_add),
      .out_alu_data(alu_data_shift_add),
      .out_q(q_shift_add)
  );

  // TODO: Logic to form commit_data_temp
  assign commit_data_temp.pc = alu_data_shift_add.common.pc;

  // Buffering pipe
  hs_skid_buffer #(
      .WIDTH($bits(commit_data_t))
  ) alu_2_commit (
      .clk_core,
      .rst_core,

      .stall,
      .flush_req,

      .in(commit_data_temp),
      .in_ready,
      .in_valid(valid_shift_add),

      .out(commit_data),
      .out_ready,
      .out_valid
  );

endmodule

module hsv_core_alu_bitwise_setup
  import hsv_core_pkg::*;
(
    input logic clk_core,

    input logic stall,
    input logic flush_req,

    input logic      in_valid,
    input alu_data_t in_alu_data,

    output logic      out_valid,
    output alu_data_t out_alu_data,
    output word       out_shift_lo,
    output word       out_shift_hi,
    output shift      out_shift_count,
    output word       out_adder_a,
    output word       out_adder_b
);

  logic shift_left;
  word operand_a_flip, operand_b, operand_b_flip, operand_b_neg;
  word in_read_rs1, in_read_rs2;

  // Extract read registers from the in_alu_data struct
  assign in_read_rs1 = in_alu_data.common.rs1;
  assign in_read_rs2 = in_alu_data.common.rs2;

  // Left-shifts by zero is an edge case. We convert them to right-shifts by
  // zero. Try to follow on what would happen if it were not checked for.
  // Regarding operand_b_neg and out_shift_count below, note that -0 = 0.
  assign shift_left = in_alu_data.negate & (operand_b != '0);

  assign operand_b = in_alu_data.is_immediate ? in_alu_data.common.immediate : in_read_rs2;
  assign operand_b_neg = in_alu_data.negate ? -operand_b : operand_b;

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
    operand_a_flip[$bits(operand_a_flip)-1] ^= in_alu_data.flip_signs;
    operand_b_flip[$bits(operand_b_flip)-1] ^= in_alu_data.flip_signs;
  end

  always_ff @(posedge clk_core) begin
    if (~stall) begin
      out_alu_data <= in_alu_data;
      out_valid <= in_valid;

      unique case (in_alu_data.bitwise_select)
        ALU_BITWISE_AND:  out_shift_lo <= in_read_rs1 & operand_b;
        ALU_BITWISE_OR:   out_shift_lo <= in_read_rs1 | operand_b;
        ALU_BITWISE_XOR:  out_shift_lo <= in_read_rs1 ^ operand_b;
        ALU_BITWISE_PASS: out_shift_lo <= shift_left ? '0 : in_read_rs1;
      endcase

      if (shift_left) out_shift_hi <= in_read_rs1;
      else
        out_shift_hi <= {($bits(
            word
        )) {in_alu_data.sign_extend & in_read_rs1[$bits(
            in_read_rs1
        )-1]}};

      // According to RISC-V spec, higher bits in the shift count must
      // be silently discarded
      out_shift_count <= operand_b_neg[$bits(out_shift_count)-1];

      out_adder_a <= in_alu_data.pc_relative ? in_alu_data.common.pc : operand_a_flip;
      out_adder_b <= operand_b_flip;
    end

    if (flush_req) out_valid <= 0;
  end

endmodule

module hsv_core_alu_shift_add
  import hsv_core_pkg::*;
(
    input logic clk_core,

    input logic stall,
    input logic flush_req,

    input logic      in_valid,
    input alu_data_t in_alu_data,
    input word       in_shift_lo,
    input word       in_shift_hi,
    input shift      in_shift_count,
    input word       in_adder_a,
    input word       in_adder_b,

    output logic      out_valid,
    output alu_data_t out_alu_data,
    output word       out_q
);

  logic adder_carry;
  word adder_q, shift_q, shift_discarded;

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
    if (in_alu_data.compare) adder_q = word'(adder_carry);
  end

  always_ff @(posedge clk_core) begin
    if (~stall) begin
      out_alu_data <= in_alu_data;
      out_valid <= in_valid;

      unique case (in_alu_data.out_select)
        ALU_OUT_ADDER: out_q <= adder_q;
        ALU_OUT_SHIFT: out_q <= shift_q;
      endcase
    end

    if (flush_req) out_valid <= 0;
  end

endmodule
