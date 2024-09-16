module hsv_core_regfile
  import hsv_core_pkg::*;
(
    input logic clk_core,
    input logic rst_core_n,

    input  reg_addr rs1_addr,
    input  reg_addr rs2_addr,
    input  reg_addr wr_addr,
    input  word     wr_data,
    input  logic    wr_en,
    output word     rs1_data,
    output word     rs2_data
);

  // 32 registers of 32-bits each.
  // The FPGA used in this design does not support dual-port
  // reading from a single memory block. To overcome this limitation
  // and allow simultaneous reading of two registers in one cycle,
  // we use two identical memory blocks (reg_array_1 and reg_array_2).
  // Each block is responsible for providing data for one of the read
  // operations, enabling us to read from both registers concurrently.
  word reg_array_1[32], reg_array_2[32];
  word rs1_data_unfiltered, rs2_data_unfiltered;
  logic rs1_was_x0, rs2_was_x0;

  // Architecturally, x0 is always zero. Writes to x0 are permitted, but
  // whatever value it might hold is then treated as zero on read
  assign rs1_data = rs1_was_x0 ? '0 : rs1_data_unfiltered;
  assign rs2_data = rs2_was_x0 ? '0 : rs2_data_unfiltered;

  // Synchronous write
  always_ff @(posedge clk_core) begin
    if (wr_en) begin
      // Both arrays are written with the same data
      reg_array_1[wr_addr] <= wr_data;
      reg_array_2[wr_addr] <= wr_data;
    end

    rs1_data_unfiltered <= reg_array_1[rs1_addr];
    rs2_data_unfiltered <= reg_array_2[rs2_addr];

    rs1_was_x0 <= rs1_addr == '0;
    rs2_was_x0 <= rs2_addr == '0;
  end

endmodule
