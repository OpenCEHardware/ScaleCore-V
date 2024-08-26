module hsv_core_issue
  import hsv_core_pkg::*;
(

    // Sequential signals
    input logic clk_core,
    input logic rst_core_n,

    // Flush signals
    input  logic flush_req,
    output logic flush_ack,

    // Input Channel (sink) signals
    input issue_data_t issue_data,
    output logic ready_o,
    input logic valid_i,

    // Output (source) signals
    output alu_data_t alu_data,
    output mem_data_t mem_data,
    output branch_data_t brach_data,
    output ctrl_status_data_t control_status_data,
    input logic ready_i,
    output logic valid_o
);

  // First stage: Masking Logic

  // Second stage: Muxing Logic

  // Third stage: Buffering pipelines (one skid buffer per PU in exec-mem)



endmodule
