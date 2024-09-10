module hsv_core_issue_hazardmask
  import hsv_core_pkg::*;
(
    input logic clk_core,
    //input logic rst_core_n,

    input logic stall,
    input logic flush_req,

    input issue_data_t issue_data,
    input logic valid_i,

    output reg_mask mask,
    output reg_mask rd_mask,
    output issue_data_t out,
    output logic valid_o
);

  reg_mask rs1;
  reg_mask rs2;
  reg_mask rd;

  word temp_rs1;
  word temp_rs2;
  word temp_rd;

  assign temp_rs1 = 1 << (issue_data.common.rs1_addr);
  assign temp_rs2 = 1 << (issue_data.common.rs2_addr);
  assign temp_rd = 1 << (issue_data.common.rd_addr);

  assign rs1 = temp_rs1[RegAmount-1:1];
  assign rs2 = temp_rs2[RegAmount-1:1];
  assign rd = temp_rd[RegAmount-1:1];

  assign out = issue_data;

  always_ff @(posedge clk_core) begin
    if (~stall) begin
      valid_o <= valid_i;

      rd_mask <= rd;
      mask <= rs1 | rs2 | rd;
    end

    if (flush_req) valid_o <= 0;
  end

endmodule
