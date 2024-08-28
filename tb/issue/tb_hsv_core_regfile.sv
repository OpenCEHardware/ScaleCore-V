module tb_hsv_core_regfile;
  import hsv_core_pkg::*;

  // Testbench signals
  logic    clk_core;
  logic    rst_n;
  reg_addr rd_addr1;
  reg_addr rd_addr2;
  reg_addr wr_addr;
  word     wr_data;
  logic    wr_en;
  word     rd_data1;
  word     rd_data2;

  // Instantiate the DUT (Device Under Test)
  hsv_core_regfile dut (
      .clk_core(clk_core),
      .rst_n(rst_n),
      .rd_addr1(rd_addr1),
      .rd_addr2(rd_addr2),
      .wr_addr(wr_addr),
      .wr_data(wr_data),
      .wr_en(wr_en),
      .rd_data1(rd_data1),
      .rd_data2(rd_data2)
  );

  // Clock generation
  always #5 clk_core = ~clk_core;

  // Waveform dump
  initial begin
    $dumpfile("tb_hsv_core_regfile.vcd");  // Specify the name of the dump file
    $dumpvars(0, tb_hsv_core_regfile);  // Dump all variables in the testbench
  end

  // Test procedure
  initial begin
    // Initialize signals
    clk_core = 0;
    rst_n = 0;
    wr_en = 0;
    wr_addr = 0;
    wr_data = 0;
    rd_addr1 = 0;
    rd_addr2 = 0;

    // Apply reset
    rst_n = 0;
    #10;
    rst_n   = 1;

    // Write data to the first register (address 3)
    wr_addr = 5'd3;
    wr_data = 32'hdeadbeef;
    wr_en   = 1;
    #10;
    wr_en   = 0;

    // Write data to the second register (address 15)
    wr_addr = 5'd15;
    wr_data = 32'hcafebabe;
    wr_en   = 1;
    #10;
    wr_en = 0;

    // Read data from both registers simultaneously
    rd_addr1 = 5'd3;
    rd_addr2 = 5'd15;
    #10;

    // Assertions to check the read values
    assert (rd_data1 == 32'hdeadbeef)
    else $fatal("Test failed: expected 0xdeadbeef at rd_data1, got %h", rd_data1);
    assert (rd_data2 == 32'hcafebabe)
    else $fatal("Test failed: expected 0xcafebabe at rd_data2, got %h", rd_data2);

    $display("Test passed: rd_data1 is 0xdeadbeef, rd_data2 is 0xcafebabe");

    // Finish simulation
    $finish;
  end

endmodule
