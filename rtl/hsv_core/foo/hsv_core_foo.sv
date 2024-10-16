module hsv_core_foo
  import hsv_core_pkg::*;
(
    // Clock and reset signals
    input logic clk_core,
    input logic rst_core_n,

    // Flush signals
    input  logic flush_req,
    output logic flush_ack,

    // Input channel (sink) signals
    input  foo_data_t foo_data,
    output logic      ready_o,
    input  logic      valid_i,

    // Output channel (source) signals
    output commit_data_t commit_data,
    input  logic         ready_i,
    output logic         valid_o
);

  logic flush, stall;

  // Modify this line if your unit can't safely flush as soon as requested.
  // E.g. pending work may need to be completed first. Remember to follow
  // the req-ack protocol (ack must never flip before req has flipped).
  assign flush   = flush_req;

  // "When should my unit wait in order to resolve a hazard?"
  //
  // This template presumes that the only way your block can stall is for the
  // output (commit skid buffer) to deassert its ready signal (stall
  // propagation). Examples of  similar execution units include ALU and Branch.
  // If your design can introduce stalls due to any other internal condition,
  // you will need to take these multiple stall sources into account here (e.g.
  // mem unit can only go as fast as RAM or I/O).
  assign stall   = ~out_ready;
  assign ready_o = ~stall;

  // Continuous combinational logic (e.g. boolean equations)
  //assign my_first_signal = ...;
  //assign my_second_signal = ...;

  logic out_ready, out_valid;
  commit_data_t out;

  // Output pipe. This links foo and commit together.
  //
  // Every execution unit has a skid buffer that acts as a buffer between
  // itself and the commit stage. You should usually leave it as-is.
  hsv_core_skid_buffer #(
      .WIDTH($bits(commit_data))
  ) foo2commit (
      .clk_core,
      .rst_core_n,

      .flush(flush_req),

      .in(out),
      .ready_o(out_ready),
      .valid_i(out_valid),

      .out(commit_data),
      .ready_i,
      .valid_o
  );

  always_comb begin
    // Procedural combinational logic (e.g. imperative if-else style)
    // ...
  end

  always_ff @(posedge clk_core) begin
    if (~stall) begin
      // Most of your sequential logic goes here. DO NOT put here any
      // registers or flip-flops that need to be reset. Note that the control
      // unit will trigger a flush immediately after reset, and so you don't
      // need to reset internal ready/valid signals as long as you flush them
      // properly (see below).
      // ...

      // This template defines a single-stage unit. See ALU for an example of
      // a two-stage unit
      out_valid <= valid_i;

      // Commit signals

      // "How does this instruction affect control flow?"
      //
      // COMMIT_NEXT:      Continue with the next instruction in the pipeline.
      //                   Set pc_next to common.pc_increment in this case.
      //
      // COMMIT_JUMP:      Flush the pipeline and jump somewhere else (next_pc)
      //                   Set pc_next to the branch target.
      //
      // COMMIT_EXCEPTION: Instruction triggered an exception; flush the
      //                   pipeline, switch to M-mode and jump to the M-mode
      //                   trap handler. In this case, you also need to set
      //                   exception_cause/value accordingly (see docs for
      //                   the 'mcause' and 'mtval' RISC-V CSRs).
      //
      // COMMIT_WFI:       Halt the core and wait for an interrupt. The
      //                   instruction immediately after this one will be
      //                   interrupted.
      //
      // COMMIT_MODE_RET:  Return from privileged mode (MRET/SRET, i.e. end of trap).
      //
      // Most instructions set COMMIT_NEXT here. Instructions that can fail
      // for any reason will conditionally set action to COMMIT_EXCEPTION.
      out.action <= COMMIT_NEXT;

      // Carry on common information found in all instructions. This line
      // should never be removed or altered under any circumstances
      out.common <= foo_data.common;

      // writeback: "Does this instruction write to the destination register?"
      // result:    "If writeback=1, what value is written to rd?"
      //
      // Note: rd is found within common, you don't have to specify it.
      out.result <= 32'hdeadc0de;
      out.writeback <= 0;

      // "What is the address of the following instruction?"
      //
      // Do not change this unless your foo unit can perform branches or jumps
      out.next_pc <= foo_data.common.pc_increment;

      // "What caused this instruction to fault?"
      //
      // Only relevant if action == COMMIT_EXCEPTION, ignored otherwise.
      out.exception_cause <= EXC_HARDWARE_ERROR;

      // Optional exception metadata. Depends on exception_cause. See the mtval
      // rules found in the privileged RISC-V spec. If unsure, leave as zero.
      out.exception_value <= '0;
    end

    if (flush) begin
      // "What should my unit do upon a pipeline flush?"
      //
      // This section will usually look similar to a synchronous reset, because we want to
      // return to a known default state after a flush
      // ...

      out_valid <= 0;
    end
  end

  always_ff @(posedge clk_core or negedge rst_core_n)
    if (~rst_core_n) begin
      // Reset values go here
      // ...

      flush_ack <= 1;
    end else begin
      // Put here all sequential logic that DOES need to be reset (usually control logic)
      // ...

      // Confirm flush entry and exit to the control unit. Don't forget to follow
      // all the req-ack rules. You will have to change this line if you have
      // altered the flush condition to be something other than just 'flush_req'
      flush_ack <= flush_req;
    end

endmodule
