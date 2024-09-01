module tb_hsv_core_issue;
  import hsv_core_pkg::*;

  // Parameters

  // Signal declarations
  logic clk_core;
  logic rst_core_n;
  logic flush_req;
  logic flush_ack;

  issue_data_t issue_data;
  logic ready_o;
  logic valid_i;

  alu_data_t alu_data;
  branch_data_t branch_data;
  ctrl_status_data_t ctrl_status_data;
  mem_data_t mem_data;

  logic alu_ready_i;
  logic branch_ready_i;
  logic ctrl_status_ready_i;
  logic mem_ready_i;

  logic alu_valid_o;
  logic branch_valid_o;
  logic ctrl_status_valid_o;
  logic mem_valid_o;

  reg_addr wr_addr;
  word wr_data;
  logic wr_en;

  // Instantiate the hsv_core_issue module
  hsv_core_issue uut (
      .clk_core(clk_core),
      .rst_core_n(rst_core_n),
      .flush_req(flush_req),
      .flush_ack(flush_ack),
      .issue_data(issue_data),
      .ready_o(ready_o),
      .valid_i(valid_i),
      .alu_data(alu_data),
      .branch_data(branch_data),
      .ctrl_status_data(ctrl_status_data),
      .mem_data(mem_data),
      .alu_ready_i(alu_ready_i),
      .branch_ready_i(branch_ready_i),
      .ctrl_status_ready_i(ctrl_status_ready_i),
      .mem_ready_i(mem_ready_i),
      .alu_valid_o(alu_valid_o),
      .branch_valid_o(branch_valid_o),
      .ctrl_status_valid_o(ctrl_status_valid_o),
      .mem_valid_o(mem_valid_o),
      .wr_addr(wr_addr),
      .wr_data(wr_data),
      .wr_en(wr_en)
  );

  // Clock generation
  initial begin
    clk_core = 0;
    forever #5 clk_core = ~clk_core;
  end

  // Waveform dump
  initial begin
    $dumpfile("tb_hsv_core_issue.vcd");  // Specify the name of the dump file
    $dumpvars(0, tb_hsv_core_issue);  // Dump all variables in the testbench
  end

  // Reset and flush control
  initial begin
    rst_core_n = 0;
    flush_req = 0;
    valid_i = 0;
    alu_ready_i = 0;
    branch_ready_i = 0;
    ctrl_status_ready_i = 0;
    mem_ready_i = 0;

    // Hold reset for 20 ns
    #20;
    rst_core_n = 1;  // Release reset

    // Flush sequence
    #10;
    flush_req = 1;
    #10;
    flush_req = 0;

    // Test sequence: Write to registers
    #10;
    issue_data.common.pc = 32'h00000000;
    issue_data.common.rs1_addr = 5'd1;
    issue_data.common.rs2_addr = 5'd0;
    issue_data.common.rd_addr = 5'd5;
    issue_data.common.immediate = 32'h00000004;
    issue_data.exec_select.alu = 1;
    valid_i = 1;
    wr_addr = 5'd0;
    wr_data = 32'hDEADBEEF;
    wr_en = 1;

    // Wait for ready signals
    #10;
    alu_ready_i = 1;
    branch_ready_i = 1;
    ctrl_status_ready_i = 1;
    mem_ready_i = 1;

    // Hold valid signal for a cycle
    #10;
    valid_i = 0;
    wr_en   = 0;

    // Read Test: Assert if values match expected
    #10;
    wr_addr = 5'd1;
    wr_data = 32'h12345678;
    wr_en   = 1;
    #10;
    wr_en = 0;

    // Simulate read operation from the register
    #10;
    //assert (uut.exec_mem_common.rs1 == 32'h12345678)
    //else $fatal("Read Test Failed: Register 1 value mismatch!");

    // Test another register
    wr_addr = 5'd2;
    wr_data = 32'h87654321;
    wr_en   = 1;
    #5;
    issue_data.common.rs2_addr = 5'd2;
    #5;
    wr_en = 0;

    #10;
    //assert (uut.exec_mem_common.rs2 == 32'h87654321)
    //else $fatal("Read Test Failed: Register 2 value mismatch!");

    // Check reading from zero register which should always return zero
    wr_addr = 5'd0;
    wr_data = 32'hBADF00D;
    wr_en   = 1;
    #10;
    wr_en = 0;

    #10;
    //assert (uut.reg_file[0] == 32'h0)
    //else $fatal("Read Test Failed: Zero Register should always read as 0!");

    // Wait for completion
    #20;
    $finish;
  end
endmodule
