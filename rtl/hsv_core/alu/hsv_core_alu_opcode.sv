module hsv_core_alu_opcode
  import hsv_core_pkg::*;
(
    input  alu_data_input_t in_alu_data,  // Input structure
    output alu_data_t       alu_data      // Output structure
);

  logic valid_opcode;


  // Combinational logic to set signals based on opcode
  always_comb begin
    // Default values
    alu_data.negate         = 1'b0;
    alu_data.flip_signs     = 1'b0;
    alu_data.bitwise_select = ALU_BITWISE_PASS;
    alu_data.sign_extend    = 1'b0;
    alu_data.is_immediate   = 1'b0;
    alu_data.compare        = 1'b0;
    alu_data.out_select     = ALU_OUT_ADDER;
    alu_data.pc_relative    = 1'b0;

    // Assign common fields directly
    alu_data.common         = in_alu_data.common;

    // Assume valid opcode until proven wrong
    valid_opcode            = 1;


    // Opcode based assignment
    case (in_alu_data.opcode)
      OPCODE_ADD, OPCODE_ADDI: begin
        alu_data.out_select   = ALU_OUT_ADDER;  // Use adder for ADD and ADDI
        alu_data.is_immediate = (in_alu_data.opcode == OPCODE_ADDI);  // Immediate for ADDI
      end

      OPCODE_SUB: begin
        alu_data.out_select = ALU_OUT_ADDER;  // Use adder for SUB
        alu_data.negate = 1'b1;  // Negate for subtraction
      end

      OPCODE_AND, OPCODE_ANDI: begin
        alu_data.out_select = ALU_OUT_SHIFT;  // Use shift (0) for bitwise operations
        alu_data.bitwise_select = ALU_BITWISE_AND;
        alu_data.is_immediate = (in_alu_data.opcode == OPCODE_ANDI);  // Immediate for ANDI
      end

      OPCODE_OR, OPCODE_ORI: begin
        alu_data.out_select = ALU_OUT_SHIFT;  // Use shift (0) for bitwise operations
        alu_data.bitwise_select = ALU_BITWISE_OR;
        alu_data.is_immediate = (in_alu_data.opcode == OPCODE_ORI);  // Immediate for ORI
      end

      OPCODE_XOR, OPCODE_XORI: begin
        alu_data.out_select = ALU_OUT_SHIFT;  // Use shift (0) for bitwise operations
        alu_data.bitwise_select = ALU_BITWISE_XOR;
        alu_data.is_immediate = (in_alu_data.opcode == OPCODE_XORI);  // Immediate for XORI
      end

      OPCODE_SLL, OPCODE_SLLI: begin
        alu_data.out_select = ALU_OUT_SHIFT;  // Use shift for SLL and SLLI
        alu_data.bitwise_select = ALU_BITWISE_PASS;  // No bitwise operation needed
        alu_data.negate = 1'b1;  //Negate for left shift
        alu_data.is_immediate = (in_alu_data.opcode == OPCODE_SLLI);  // Immediate for SLLI
      end

      OPCODE_SRL, OPCODE_SRLI: begin
        alu_data.out_select = ALU_OUT_SHIFT;  // Use shift for SRL and SRLI
        alu_data.bitwise_select = ALU_BITWISE_PASS;  // No bitwise operation needed
        alu_data.is_immediate = (in_alu_data.opcode == OPCODE_SRLI);  // Immediate for SRLI
      end

      OPCODE_SRA, OPCODE_SRAI: begin
        alu_data.out_select = ALU_OUT_SHIFT;  // Use shift for SRA and SRAI
        alu_data.bitwise_select = ALU_BITWISE_PASS;  // No bitwise operation needed
        alu_data.sign_extend = 1'b1;  // Arithmetic shift needs sign extension
        alu_data.is_immediate = (in_alu_data.opcode == OPCODE_SRAI);  // Immediate for SRAI
      end

      OPCODE_SLT, OPCODE_SLTI, OPCODE_SLTU, OPCODE_SLTIU: begin
        alu_data.compare = 1'b1;
        alu_data.out_select = ALU_OUT_ADDER;  // Comparison uses the adder
        alu_data.is_immediate = (in_alu_data.opcode == OPCODE_SLTI || in_alu_data.opcode == OPCODE_SLTIU); // Immediate for SLTI, SLTIU
        alu_data.flip_signs = (in_alu_data.opcode == OPCODE_SLT || in_alu_data.opcode == OPCODE_SLTI); // Sign flio for SLT, SLTI
      end

      OPCODE_LUI: begin
        alu_data.out_select   = ALU_OUT_ADDER;  // Use adder for LUI
        alu_data.is_immediate = 1'b1;
      end

      OPCODE_AUIPC: begin
        alu_data.out_select   = ALU_OUT_ADDER;  // Use adder for AUIPC
        alu_data.is_immediate = 1'b1;
        alu_data.pc_relative  = 1'b1;  // Relative to PC
      end

      // Theres still room for 11 more unsed opcodes

      default: begin
        // Default case to handle unexpected opcodes
        valid_opcode = 0;
        //TODO: Special trap cause for invalid ALU opcode
      end
    endcase

    alu_data.illegal = valid_opcode ? in_alu_data.illegal : 0;

  end
endmodule
