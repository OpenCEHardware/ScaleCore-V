`timescale 1ns / 1ps

module tb_hsv_core_alu;
  import hsv_core_pkg::*;

  // Clock and Reset
  logic clk_core;
  logic rst_core_n;

  // DUT signals
  logic flush_req;
  logic flush_ack;

  logic ready_o;
  logic valid_i;
  alu_data_input_t alu_data;

  logic ready_i;
  logic valid_o;
  commit_data_t commit_data;

  // Instantiate DUT (Device Under Test)
  hsv_core_alu dut (
      .clk_core,
      .rst_core_n,
      .flush_req,
      .flush_ack,
      .alu_data,
      .ready_o,
      .valid_i,
      .commit_data,
      .ready_i,
      .valid_o
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
    $dumpfile("tb_hsv_core_alu.vcd");  // Name of the dump file
    $dumpvars(0, tb_hsv_core_alu);  // Dump all variables in the testbench
  end

  // Testbench logic
  initial begin

    // Initialize inputs
    flush_req = 0;
    valid_i   = 0;
    alu_data  = '0;
    ready_i   = 1;

    // Wait for reset
    wait (rst_core_n);

    // Test case 1: Basic ADD operation
    wait (ready_o);

    alu_data.common.token = 8'd1;
    alu_data.common.pc = 32'd0;
    alu_data.common.pc_increment = 32'd4;
    alu_data.common.rs1_addr = 5'd5;
    alu_data.common.rs2_addr = 5'd10;
    alu_data.common.rd_addr = 5'd15;
    alu_data.common.rs1 = 32'd1;
    alu_data.common.rs2 = 32'd2;
    alu_data.common.immediate = 32'd0;

    alu_data.illegal = 0;
    alu_data.opcode = OPCODE_ADD;

    valid_i = 1;

    // Wait for output
    wait (valid_o);
    if (commit_data.result == (32'd1 + 32'd2)) begin
      $display("Test case 1 passed.");
    end else begin
      $display("Test case 1 failed.");
    end

    // Test case 2: OR operation with immediate

    valid_i = 0;

    wait (ready_o & ~valid_o) alu_data.common.pc = '0;
    alu_data.common.rs1 = 32'h5A5A5A5A;
    alu_data.common.rs2 = 32'h5ACA5A5B;
    alu_data.common.immediate = 32'h5A5A5A5A;

    alu_data.opcode = OPCODE_ORI;

    valid_i = 1;

    // Wait for output
    wait (valid_o);
    if (commit_data.result == (32'h5A5A5A5A | 32'h5A5A5A5A)) begin
      $display("Test case 2 passed.");
    end else begin
      $display("Test case 2 failed.");
    end

    // // More test cases can be added here

    // Finish simulation
    #10;
    $finish();
  end

endmodule
