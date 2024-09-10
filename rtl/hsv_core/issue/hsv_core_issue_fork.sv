module hsv_core_issue_fork
  import hsv_core_pkg::*;
(
    input logic clk_core,
    //input logic rst_core_n,

    input logic stall,
    input logic alu_stall,
    input logic foo_stall,
    input logic mem_stall,
    input logic branch_stall,
    input logic ctrl_status_stall,
    input logic exec_mem_stall,

    input logic flush_req,

    input issue_data_t issue_data,
    input reg_mask mask,
    input reg_mask rd_mask,
    input reg_mask commit_mask,
    output reg_addr rs1_addr,
    output reg_addr rs2_addr,
    input word rs1_data,
    input word rs2_data,
    input logic valid_i,

    output logic alu_valid_o,
    output logic foo_valid_o,
    output logic mem_valid_o,
    output logic branch_valid_o,
    output logic ctrl_status_valid_o,

    output alu_data_t alu_data,
    output foo_data_t foo_data,
    output mem_data_t mem_data,
    output branch_data_t branch_data,
    output ctrl_status_data_t ctrl_status_data,

    output logic hazard
);

  reg_addr last_rs1_addr, last_rs2_addr;
  exec_mem_common_t exec_mem_common;
  assign rs1_addr = exec_mem_stall ? last_rs1_addr : issue_data.common.rs1_addr;
  assign rs2_addr = exec_mem_stall ? last_rs2_addr : issue_data.common.rs2_addr;

  reg_mask pending_write, pending_write_next;
  assign hazard = (pending_write & mask) != '0;

  alu_data_t alu_data_next;
  foo_data_t foo_data_next;
  mem_data_t mem_data_next;
  branch_data_t branch_data_next;
  ctrl_status_data_t ctrl_status_data_next;

  // We increment this counter each time an instruction is issued. Every
  // instruction is issued along with a copy of token's current value. Later
  // on, the commit stage makes use of the carried-over token to select
  // instructions in the same order they were issued.
  insn_token token;

  always_comb begin
    pending_write_next = pending_write & ~commit_mask;
    if (~stall & valid_i) pending_write_next |= rd_mask;

    alu_data = alu_data_next;
    foo_data = foo_data_next;
    mem_data = mem_data_next;
    branch_data = branch_data_next;
    ctrl_status_data = ctrl_status_data_next;

    alu_data.common.rs1 = rs1_data;
    foo_data.common.rs1 = rs1_data;
    mem_data.common.rs1 = rs1_data;
    branch_data.common.rs1 = rs1_data;
    ctrl_status_data.common.rs1 = rs1_data;

    alu_data.common.rs2 = rs2_data;
    foo_data.common.rs2 = rs2_data;
    mem_data.common.rs2 = rs2_data;
    branch_data.common.rs2 = rs2_data;
    ctrl_status_data.common.rs2 = rs2_data;

    exec_mem_common.pc = issue_data.common.pc;
    exec_mem_common.pc_increment = issue_data.common.pc_increment;
    exec_mem_common.immediate = issue_data.common.immediate;
    exec_mem_common.token = token;
  end

  // issue_data_t data;
  // assign data.common = issue_data.common;
  // assign data.exec_select = issue_data.exec_select;
  // assign data.exec_mem_data.branch_data.common = exec_mem_common;
  // assign data.exec_mem_data.ctrl_status_data.common = exec_mem_common;
  // assign data.exec_mem_data.mem_data.common = exec_mem_common;

  always_ff @(posedge clk_core) begin
    automatic logic common_valid = valid_i & ~hazard;

    if (~stall) begin
      last_rs1_addr <= issue_data.common.rs1_addr;
      last_rs2_addr <= issue_data.common.rs2_addr;

      if (valid_i) token <= token + 1;
    end

    if (~alu_stall) begin
      alu_valid_o          <= common_valid & issue_data.exec_select.alu;
      alu_data_next        <= issue_data.exec_mem_data.alu_data;
      alu_data_next.common <= exec_mem_common;
    end

    if (~foo_stall) begin
      foo_valid_o          <= common_valid & issue_data.exec_select.foo;
      foo_data_next        <= issue_data.exec_mem_data.foo_data;
      foo_data_next.common <= exec_mem_common;
    end

    if (~mem_stall) begin
      mem_valid_o          <= common_valid & issue_data.exec_select.mem;
      mem_data_next        <= issue_data.exec_mem_data.mem_data;
      mem_data_next.common <= exec_mem_common;
    end

    if (~branch_stall) begin
      branch_valid_o          <= common_valid & issue_data.exec_select.branch;
      branch_data_next        <= issue_data.exec_mem_data.branch_data;
      branch_data_next.common <= exec_mem_common;
    end

    if (~ctrl_status_stall) begin
      ctrl_status_valid_o          <= common_valid & issue_data.exec_select.ctrl_status;
      ctrl_status_data_next        <= issue_data.exec_mem_data.ctrl_status_data;
      ctrl_status_data_next.common <= exec_mem_common;
    end

    pending_write <= pending_write_next;

    if (flush_req) begin
      alu_valid_o         <= 0;
      branch_valid_o      <= 0;
      ctrl_status_valid_o <= 0;
      mem_valid_o         <= 0;

      token               <= '0;
      pending_write       <= '0;
    end
  end

endmodule
