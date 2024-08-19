module test_alu_ready_valid;
  import hsv_core_pkg::*;
  // Clock and Reset
  logic clk_core;
  logic rst_core_n;

  // DUT signals
  logic flush_req;
  logic flush_ack;

  logic in_ready;
  logic in_valid;
  alu_data_t alu_data;

  logic out_ready;
  logic out_valid;
  commit_data_t commit_data;

  // Instantiate DUT (Device Under Test)
  hsv_core_alu dut (
      .clk_core(clk_core),
      .rst_core_n(rst_core_n),
      .flush_req(flush_req),
      .flush_ack(flush_ack),
      .alu_data(alu_data),
      .in_ready(in_ready),
      .in_valid(in_valid),
      .commit_data(commit_data),
      .out_ready(out_ready),
      .out_valid(out_valid)
  );

  // Clock generation
  initial begin
    clk_core = 0;
    forever #5 clk_core = ~clk_core;  // 10ns clock period
  end

  // Reset logic
  initial begin
    rst_core_n = 0;
    #20 rst_core_n = 1;
  end

  // Waveform dump
  initial begin
    $dumpfile("hsv_core_alu_tb.vcd");  // Specify the name of the dump file
    $dumpvars(0, hsv_core_alu_tb);  // Dump all variables in the testbench
  end

  // Testbench logic
  initial begin
    // Initialize inputs
    flush_req = 0;
    in_valid  = 0;
    alu_data  = '0;
    out_ready = 1;

    // Wait for reset
    wait (rst_core_n);

    // Test case 1: Basic AND operation
    wait (in_ready);

    alu_data.illegal = 0;

    alu_data.common.pc = '0;
    alu_data.common.rs1 = 32'h00000010;
    alu_data.common.rs2 = 32'h00000010;
    alu_data.common.immediate = 0;

    alu_data.negate = 0;
    alu_data.flip_signs = 0;
    alu_data.bitwise_select = ALU_BITWISE_AND;
    alu_data.sign_extend = 0;
    alu_data.is_immediate = 0;
    alu_data.compare = 0;
    alu_data.out_select = ALU_OUT_SHIFT;
    alu_data.pc_relative = 0;

    in_valid = 1;

    // Wait for output
    wait (out_valid);
    if (commit_data.result == (32'h00000010 & 32'h00000010)) begin
      $display("Test case 1 passed.");
    end else begin
      $display("Test case 1 failed.");
    end

    in_valid = 0;

    wait (in_ready & ~out_valid) alu_data.common.pc = '0;
    alu_data.common.rs1 = 32'h5A5A5A5A;
    alu_data.common.rs2 = 32'h5A5A5A5A;
    alu_data.common.immediate = 32'h5A5A5A5A;

    alu_data.negate = 0;
    alu_data.flip_signs = 0;
    alu_data.bitwise_select = ALU_BITWISE_OR;
    alu_data.sign_extend = 0;
    alu_data.is_immediate = 1;
    alu_data.compare = 0;
    alu_data.out_select = ALU_OUT_SHIFT;
    alu_data.pc_relative = 0;

    in_valid = 1;

    // Test case 2: OR operation with immediate

    // Wait for output
    wait (out_valid);
    if (commit_data.result == (32'h5A5A5A5A | 32'h5A5A5A5A)) begin
      $display("Test case 2 passed.");
    end else begin
      $display("Test case 2 failed.");
    end

    // More test cases can be added here

    // Finish simulation
    #100;
    $finish();
  end

endmodule
