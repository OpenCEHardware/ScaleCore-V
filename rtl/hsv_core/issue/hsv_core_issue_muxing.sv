module hsv_core_issue_muxing
  import hsv_core_pkg::*;
(
    input logic clk_core,
    //input logic rst_core_n,

    input logic stall,
    input logic alu_stall,
    input logic branch_stall,
    input logic ctrl_status_stall,
    input logic mem_stall,
    input logic exec_mem_stall,

    input logic flush_req,

    input issue_data_t issue_data,
    input reg_mask mask,
    input reg_mask rd_mask,
    input word rs1_data,
    input word rs2_data,
    input logic valid_i,

    output logic alu_valid_o,
    output logic branch_valid_o,
    output logic ctrl_status_valid_o,
    output logic mem_valid_o,

    output alu_data_t alu_data,
    output branch_data_t branch_data,
    output ctrl_status_data_t ctrl_status_data,
    output mem_data_t mem_data,

    output logic hazard
);

  word last_rs1;
  word last_rs2;
  word rs1;
  word rs2;
  exec_mem_common_t exec_mem_common;
  assign rs1 = exec_mem_stall ? last_rs1 : rs1_data;
  assign rs2 = exec_mem_stall ? last_rs2 : rs2_data;

  reg_mask pending_write;
  assign hazard = (pending_write & mask) != '0;

  // issue_data_t data;
  // assign data.common = issue_data.common;
  // assign data.exec_select = issue_data.exec_select;
  // assign data.exec_mem_data.branch_data.common = exec_mem_common;
  // assign data.exec_mem_data.ctrl_status_data.common = exec_mem_common;
  // assign data.exec_mem_data.mem_data.common = exec_mem_common;

  always_ff @(posedge clk_core) begin
    logic common_valid = valid_i & ~hazard;

    last_rs1 <= rs1;
    last_rs2 <= rs2;

    exec_mem_common.rs1 <= rs1;
    exec_mem_common.rs2 <= rs2;
    exec_mem_common.pc <= issue_data.common.pc;
    exec_mem_common.immediate <= issue_data.common.immediate;

    if (~alu_stall) begin
      alu_valid_o     <= common_valid & issue_data.exec_select.alu;
      alu_data        <= issue_data.exec_mem_data.alu_data;
      alu_data.common <= exec_mem_common;
    end

    if (~branch_stall) begin
      branch_valid_o     <= common_valid & issue_data.exec_select.branch;
      branch_data        <= issue_data.exec_mem_data.branch_data;
      branch_data.common <= exec_mem_common;

    end

    if (~ctrl_status_stall) begin
      ctrl_status_valid_o <= common_valid & issue_data.exec_select.ctrl_status;
      ctrl_status_data    <= issue_data.exec_mem_data.ctrl_status_data;
      ctrl_status_data.common <= exec_mem_common;

    end

    if (~mem_stall) begin
      mem_valid_o     <= common_valid & issue_data.exec_select.mem;
      mem_data        <= issue_data.exec_mem_data.mem_data;
      mem_data.common <= exec_mem_common;

    end

    if (~stall & valid_i) pending_write <= pending_write | rd_mask;

    if (flush_req) begin
      alu_valid_o         <= 0;
      branch_valid_o      <= 0;
      ctrl_status_valid_o <= 0;
      mem_valid_o         <= 0;
    end
  end

endmodule
