module tb_hsv_core_issue_hazardmask;
  import hsv_core_pkg::*;

  // Parameters
  logic clk_core;
  logic stall;
  logic flush_req;
  logic valid_i;
  logic valid_o;

  // Data types
  issue_data_t issue_data;
  reg_mask mask;
  reg_mask rd_mask;

  // Module instantiation
  hsv_core_issue_hazardmask uut (
      .clk_core(clk_core),
      .stall(stall),
      .flush_req(flush_req),
      .issue_data(issue_data),
      .valid_i(valid_i),
      .mask(mask),
      .rd_mask(rd_mask),
      .valid_o(valid_o)
  );

  // Clock generation
  initial begin
    clk_core = 0;
    forever #5 clk_core = ~clk_core;  // 100 MHz clock (period = 10 ns)
  end

  // Waveform dump
  initial begin
    $dumpfile("tb_hsv_core_issue_hazardmask.vcd");  // Specify the name of the dump file
    $dumpvars(0, tb_hsv_core_issue_hazardmask);  // Dump all variables in the testbench
  end

  // Test sequence
  initial begin
    // Initialize signals
    stall = 0;
    flush_req = 0;
    valid_i = 0;
    issue_data.common.rs1_addr = 0;
    issue_data.common.rs2_addr = 0;
    issue_data.common.rd_addr = 0;

    // Reset sequence
    #10;
    valid_i = 1;
    issue_data.common.rs1_addr = 5;  // Example address
    issue_data.common.rs2_addr = 10;  // Example address
    issue_data.common.rd_addr = 15;  // Example address

    #10;
    $display("After first operation:");
    $display("mask = %b", mask);
    $display("rd_mask = %b", rd_mask);
    $display("valid_o = %b", valid_o);

    // Test stall
    stall = 1;
    #10;
    $display("During stall:");
    $display("mask = %b", mask);
    $display("rd_mask = %b", rd_mask);
    $display("valid_o = %b", valid_o);

    // Test flush
    stall = 0;
    flush_req = 1;
    #10;
    $display("After flush:");
    $display("mask = %b", mask);
    $display("rd_mask = %b", rd_mask);
    $display("valid_o = %b", valid_o);

    // Complete simulation
    $finish;
  end
endmodule
