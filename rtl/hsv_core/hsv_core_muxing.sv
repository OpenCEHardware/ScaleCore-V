module hsv_core_muxing
  import hsv_core_pkg::*;
(
    input logic clk_core,
    //input logic rst_core_n,

    input logic stall,
    input logic flush_req,

    input issue_data_t issue_data,
    input reg_mask mask,
    input reg_mask rd_mask,
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

  reg_mask pending_write;

  assign hazard = (pending_write & mask) != '0;

  always_ff @(posedge clk_core) begin
    if (~stall) begin
      logic common_valid = valid_i & ~hazard;
      alu_valid_o         <= common_valid & issue_data.exec_select.alu;
      branch_valid_o      <= common_valid & issue_data.exec_select.branch;
      ctrl_status_valid_o <= common_valid & issue_data.exec_select.ctrl_status;
      mem_valid_o         <= common_valid & issue_data.exec_select.mem;

      alu_data            <= issue_data.exec_mem_data.alu_data;
      branch_data         <= issue_data.exec_mem_data.branch_data;
      ctrl_status_data    <= issue_data.exec_mem_data.ctrl_status_data;
      mem_data            <= issue_data.exec_mem_data.mem_data;
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
