module hsv_core_alu
  import hsv_core_pkg::*;
(

    // Sequential signals
    input logic clk_core,
    input logic rst_core_n,

    // Flush signals
    input  logic flush_req,
    output logic flush_ack,

    // Input Channel (sink) signals
    input alu_data_t alu_data,
    output logic ready_o,
    input logic valid_i,

    // Output (source) signals
    output commit_data_t commit_data,
    input logic ready_i,
    output logic valid_o
);

  logic         stall;

  logic         valid_setup;
  alu_data_t    alu_data_setup;

  word          shift_lo;
  word          shift_hi;
  shift         shift_count;
  adder_in      adder_a;
  adder_in      adder_b;

  logic         valid_shift_add;
  commit_data_t out_shift_add;
  word          q_shift_add;

  // First Stage
  hsv_core_alu_bitwise_setup setup (
      .clk_core,

      .stall,
      .flush_req,

      .valid_i,
      .in_alu_data(alu_data),

      .valid_o(valid_setup),
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

      .valid_i(valid_setup),
      .in_alu_data(alu_data_setup),
      .in_shift_lo(shift_lo),
      .in_shift_hi(shift_hi),
      .in_shift_count(shift_count),
      .in_adder_a(adder_a),
      .in_adder_b(adder_b),

      .out(out_shift_add),
      .valid_o(valid_shift_add)
  );

  // Buffering pipe
  hs_skid_buffer #(
      .WIDTH($bits(commit_data))
  ) alu_2_commit (
      .clk_core,
      .rst_core_n,

      .stall,
      .flush_req,

      .in(out_shift_add),
      .ready_o,
      .valid_i(valid_shift_add),

      .out(commit_data),
      .ready_i,
      .valid_o
  );

  always_ff @(posedge clk_core or negedge rst_core_n)
    if (~rst_core_n) flush_ack <= 0;
    else flush_ack <= flush_req;

endmodule

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

  // Extract read registers from the in_alu_data struct
  assign operand_a = in_alu_data.common.rs1;
  assign operand_b = in_alu_data.is_immediate ? in_alu_data.common.immediate : in_alu_data.common.rs2;

  // Left-shifts by zero is an edge case. We convert them to right-shifts by
  // zero. Try to follow on what would happen if it were not checked for.
  // Regarding operand_b_neg and out_shift_count below, note that -0 = 0.
  assign shift_left = in_alu_data.negate & operand_b_non_zero;

  // Sign-extend to 33 bits for adder
  assign operand_a_ext = {operand_a[$bits(operand_a)-1], operand_a};
  assign operand_b_ext = {operand_b[$bits(operand_b)-1], operand_b};

  assign operand_b_neg = in_alu_data.negate ? -operand_b_ext : operand_b_ext;
  assign operand_b_non_zero = operand_b != '0;

  always_comb begin
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

module hsv_core_alu_shift_add
  import hsv_core_pkg::*;
(
    input logic clk_core,

    input logic stall,
    input logic flush_req,

    input logic      valid_i,
    input alu_data_t in_alu_data,
    input word       in_shift_lo,
    input word       in_shift_hi,
    input shift      in_shift_count,
    input adder_in   in_adder_a,
    input adder_in   in_adder_b,

    output logic         valid_o,
    output commit_data_t out
);

  word adder_q, alu_q, shift_q, shift_discarded;
  logic adder_carry;

  // All three types of shifts (sll, slr, sra) are implemented using a single
  // right shifter. The shifter takes a 64-bit input (32-bit high + 32-bit low).
  //
  // If x is the data to shift and n is the number of bits to shift, each type
  // of shift is translated to right shifts as follows:
  //
  // srl (x  >> n): {0000...0000, x} >> n
  // sra (x >>> n): {ssss...ssss, x} >> n where s = x[31]
  // sll (x  << n):  {x, 0000..0000} >> (32 - n)
  //
  // Higher half of the result is always discarded.
  assign {shift_discarded, shift_q} = {in_shift_hi, in_shift_lo} >> in_shift_count;

  always_comb begin
    // The 33-bit adder
    {adder_carry, adder_q} = in_adder_a + in_adder_b;

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
    // equivalent signed versions by introducing a 33rd bit to each operand
    // before adding. We don't have to negate src2, that has already been
    // done by the previous substage. The extra bit from the adder output
    // is the comparison's result (1 if src1 < src2, 0 otherwise).
    if (in_alu_data.compare) adder_q = word'(adder_carry);

    unique case (in_alu_data.out_select)
      ALU_OUT_ADDER: alu_q = adder_q;
      ALU_OUT_SHIFT: alu_q = shift_q;
    endcase
  end

  word out_next_pc, out_result;
  logic out_illegal;
  common_data_t out_common;

  assign out.jump = 0;
  assign out.trap = out_illegal;
  assign out.common = out_common;
  assign out.result = out_result;
  assign out.next_pc = out_next_pc;
  assign out.writeback = 1;

  always_ff @(posedge clk_core) begin
    if (~stall) begin
      valid_o <= valid_i;

      out_common <= in_alu_data.common;
      out_result <= alu_q;
      out_illegal <= in_alu_data.illegal;
      out_next_pc <= in_alu_data.common.pc_increment;
    end

    if (flush_req) valid_o <= 0;
  end

endmodule
