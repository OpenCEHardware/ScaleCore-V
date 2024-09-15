module hsv_core_alu_tb_top
  import hsv_core_pkg::*;
(

    // Sequential signals
    input logic clk_core,
    input logic rst_core_n,

    // Flush signals
    input  logic flush_req,
    output logic flush_ack,

    // Input Channel (sink) signals
    input  alu_opcode opcode,
    input  logic      illegal,
    input  insn_token token,
    input  word       pc,
    input  word       pc_increment,
    input  reg_addr   rs1_addr,
    input  reg_addr   rs2_addr,
    input  reg_addr   rd_addr,
    input  word       rs1,
    input  word       rs2,
    input  word       immediate,
    output logic      ready_o,
    input  logic      valid_i,

    // Output (source) signals
    output word result,
    input logic ready_i,
    output logic valid_o
);

  alu_data_t alu_data;
  exec_mem_common_t common;
  commit_data_t commit_data;

  assign common.pc            = pc;
  assign common.pc_increment  = pc_increment;
  assign common.rs1_addr      = rs1_addr;
  assign common.rs2_addr      = rs2_addr;
  assign common.rd_addr       = rd_addr;
  assign common.rs1           = rs1;
  assign common.rs2           = rs2;
  assign common.immediate     = immediate;

  hsv_core_alu_opcode decode (.*);

  hsv_core_alu alu (.*);

  assign result = commit_data.result;

endmodule

