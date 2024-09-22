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
      default:       alu_q = 'x;
    endcase
  end

  word out_next_pc, out_result;
  logic out_illegal;
  exec_mem_common_t out_common;

  assign out.action = out_illegal ? COMMIT_EXCEPTION : COMMIT_NEXT;
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
