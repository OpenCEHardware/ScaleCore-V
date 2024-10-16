module hsv_core_fetch
  import hsv_core_pkg::*;
#(
    parameter int BURST_LEN = 4
) (
    input logic clk_core,
    input logic rst_core_n,

    input  word  flush_target,
    input  logic flush_req,
    output logic flush_ack,

    output fetch_data_t fetch_data,
    input  logic        ready_i,
    output logic        valid_o,

    axib_if.m imem
);

  localparam int BytesPerInsn = $bits(word) / 8;

  typedef enum int unsigned {
    FLUSH,
    FETCH_0,  // No burst is pending, request two of those ASAP
    FETCH_1,  // One burst is pending, request another one ASAP
    FETCH_2   // Two bursts are pending, wait for one of them to complete
  } state_t;

  typedef struct packed {
    logic      last;
    axi_resp_t resp;
    word       data;
  } fetch_read_t;

  word burst_base, pc, pc_increment;
  logic fetch_beat, fetch_start, fetch_end, fetch_ready, fetch_valid;
  state_t state, next_state;
  fetch_read_t fetch_read_in, fetch_read_out;

  assign fetch_end = fetch_beat & fetch_read_out.last;
  assign fetch_beat = fetch_valid & fetch_ready;
  assign fetch_start = imem.arvalid & imem.arready;

  assign fetch_read_in.data = imem.rdata;
  assign fetch_read_in.last = imem.rlast;
  assign fetch_read_in.resp = axi_resp_t'(imem.rresp);

  // We disable all write signals since imem is read-only

  assign imem.awid = 'x;
  assign imem.awlen = 'x;
  assign imem.awaddr = 'x;
  assign imem.awsize = 'x;
  assign imem.awburst = 'x;
  assign imem.awvalid = 0;

  assign imem.wdata = 'x;
  assign imem.wlast = 'x;
  assign imem.wstrb = 'x;
  assign imem.wvalid = 0;

  assign imem.bready = 0;

  // We use a single fetch stream (no hardware multithreading), there's no need for read IDs
  assign imem.arid = '0;
  // Address we want to fetch from
  assign imem.araddr = burst_base;
  // Incremental burst mode (fetch reads succesive instruction words)
  assign imem.arburst = AXI_BURST_INCR;
  // 4 bytes (1 word) per beat
  assign imem.arsize = AXI_SIZE_4;
  // We request 4 instructions in advance per beat (prefetching)
  assign imem.arlen = ($bits(imem.arlen))'(BURST_LEN - 1);

  assign valid_o = fetch_valid;
  assign fetch_ready = ready_i;

  assign fetch_data.pc = pc;
  assign fetch_data.insn = fetch_read_out.data;
  assign fetch_data.fault = is_axi_error(fetch_read_out.resp);
  assign fetch_data.pc_increment = pc_increment;

  // Without this FIFO, fetch and memory loads can deadlock one another,
  // depending on memory interconnect implementation. This was observed
  // on a Platform Designer system with a shared imem/dmem on-chip RAM.
  hsv_core_fifo #(
      .WIDTH($bits(fetch_read_t)),
      .DEPTH(1 << $clog2(2 * BURST_LEN + 1))
  ) anti_contention_fifo (
      .clk_core,
      .rst_core_n,

      .flush(0),

      .in(fetch_read_in),
      .ready_o(imem.rready),
      .valid_i(imem.rvalid),

      .out(fetch_read_out),
      .ready_i(fetch_ready),
      .valid_o(fetch_valid)
  );

  always_comb begin
    flush_ack = 0;
    imem.arvalid = 0;

    unique case (state)
      FLUSH: flush_ack = 1;

      FETCH_0: imem.arvalid = 1;

      FETCH_1: imem.arvalid = 1;

      // Nothing to do here but wait, we already have two outstanding bursts in place
      FETCH_2: ;

      default: ;
    endcase

    if (flush_req) imem.arvalid = 0;

    next_state = state;
    unique case (state)
      FLUSH: if (~flush_req) next_state = FETCH_0;

      FETCH_0:
      if (flush_req) next_state = FLUSH;
      else if (fetch_start) next_state = FETCH_1;

      FETCH_1:
      if (fetch_start & ~fetch_end) next_state = FETCH_2;
      else if (~fetch_start & fetch_end) next_state = FETCH_0;

      FETCH_2: if (fetch_end) next_state = FETCH_1;

      default: ;
    endcase
  end

  always_ff @(posedge clk_core or negedge rst_core_n)
    if (~rst_core_n) state <= FLUSH;
    else state <= next_state;

  always_ff @(posedge clk_core) begin
    if (fetch_start) burst_base <= burst_base + word'(BytesPerInsn * BURST_LEN);

    if (fetch_beat) pc <= pc_increment;

    if (fetch_beat | (~flush_req & flush_ack)) pc_increment <= pc_increment + word'(BytesPerInsn);

    if (flush_req) begin
      burst_base <= flush_target;

      pc <= flush_target;
      pc_increment <= flush_target;
    end
  end

endmodule
