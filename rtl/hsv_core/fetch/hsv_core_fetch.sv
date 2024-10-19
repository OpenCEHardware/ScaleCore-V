module hsv_core_fetch
  import hsv_core_pkg::*;
#(
    parameter int BURST_LEN = 4
) (
    input logic clk_core,
    input logic rst_core_n,

    input  word  flush_target,
    input  logic flush_halt,
    input  logic flush_req,
    output logic flush_ack,

    output fetch_data_t fetch_data,
    input  logic        ready_i,
    output logic        valid_o,

    axib_if.m imem
);

  localparam int BytesPerInsn = $bits(word) / 8;

  typedef enum int unsigned {
    FENCE,
    FETCH_0,  // No burst is pending, request two of those ASAP
    FETCH_1,  // One burst is pending, request another one ASAP
    FETCH_2   // Two bursts are pending, wait for one of them to complete
  } state_t;

  typedef struct packed {
    logic      last;
    axi_resp_t resp;
    word       data;
  } fetch_read_t;

  word burst_base, fetch_addr, pc, pc_increment;
  logic fence_exit, fetch_addr_ready, fetch_addr_valid;
  logic fetch_beat, fetch_end, fetch_last, fetch_start, fetch_ready, fetch_valid;
  logic flush_posedge;
  state_t state, next_state;
  logic[3:0] discard_beats, discard_beats_add, discard_beats_next;
  fetch_read_t fetch_read_in, fetch_read_out;

  assign fetch_end = fetch_beat & fetch_last;
  assign fetch_beat = fetch_valid & fetch_ready & (discard_beats == '0);
  assign fetch_last = fetch_read_out.last;
  assign fetch_start = fetch_addr_valid & fetch_addr_ready;

  assign fetch_read_in.data = imem.rdata;
  assign fetch_read_in.last = imem.rlast;
  assign fetch_read_in.resp = axi_resp_t'(imem.rresp);

  assign flush_posedge = flush_req & ~flush_halt & ~flush_ack;

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
  assign fetch_addr = burst_base;
  // Incremental burst mode (fetch reads succesive instruction words)
  assign imem.arburst = AXI_BURST_INCR;
  // 4 bytes (1 word) per beat
  assign imem.arsize = AXI_SIZE_4;
  // We request 4 instructions in advance per beat (prefetching)
  assign imem.arlen = ($bits(imem.arlen))'(BURST_LEN - 1);

  assign valid_o = fetch_valid & ~flush_ack & (discard_beats == '0);
  assign fetch_ready = (ready_i & ~flush_ack) | (discard_beats != '0);

  assign fetch_data.pc = pc;
  assign fetch_data.insn = fetch_read_out.data;
  assign fetch_data.fault = is_axi_error(fetch_read_out.resp);
  assign fetch_data.pc_increment = pc_increment;

  hsv_core_skid_buffer #(
      .WIDTH($bits(fetch_addr))
  ) imem_addr_skid (
      .clk_core,
      .rst_core_n,

      .flush(0),

      .in(fetch_addr),
      .ready_o(fetch_addr_ready),
      .valid_i(fetch_addr_valid),

      .out(imem.araddr),
      .ready_i(imem.arready),
      .valid_o(imem.arvalid)
  );

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
    fence_exit = 0;
    fetch_addr_valid = 0;
    discard_beats_add = '0;

    unique case (state)
      FENCE: if (~flush_req) fence_exit = 1;

      FETCH_0: fetch_addr_valid = 1;

      FETCH_1: begin
        fetch_addr_valid = 1;
        discard_beats_add = 'd1;
      end

      // Nothing to do here but wait, we already have two outstanding bursts in place
      FETCH_2: begin
        discard_beats_add = 'd2;
      end

      default: ;
    endcase

    if (flush_posedge | flush_halt) fetch_addr_valid = 0;

    next_state = state;
    unique case (state)
      FENCE: if (~flush_req) next_state = FETCH_0;

      FETCH_0:
      if (flush_posedge) next_state = FETCH_0;
      else if (fetch_start) next_state = FETCH_1;

      FETCH_1:
      if (flush_posedge) next_state = FETCH_0;
      else if (fetch_start & ~fetch_end) next_state = FETCH_2;
      else if (~fetch_start & fetch_end) next_state = FETCH_0;

      FETCH_2:
      if (flush_posedge) next_state = FETCH_0;
      else if (fetch_end) next_state = FETCH_1;

      default: ;
    endcase

    discard_beats_next = discard_beats;

    if (flush_posedge)
      discard_beats_next += discard_beats_add;

    if (fetch_ready & fetch_valid & fetch_last & ((discard_beats != '0) | flush_posedge))
      discard_beats_next--;
  end

  always_ff @(posedge clk_core or negedge rst_core_n)
    if (~rst_core_n) begin
      state <= FENCE;
      flush_ack <= 1;
      discard_beats <= '0;
    end else begin
      state <= next_state;
      flush_ack <= flush_req & ~flush_halt;
      discard_beats <= discard_beats_next;
    end

  always_ff @(posedge clk_core) begin
    if (fetch_start) burst_base <= burst_base + word'(BytesPerInsn * BURST_LEN);

    if (fetch_beat) begin
      pc <= pc_increment;
      pc_increment <= pc_increment + word'(BytesPerInsn);
    end

    if (flush_posedge | fence_exit) begin
      burst_base <= flush_target;

      pc <= flush_target;
      pc_increment <= flush_target + word'(BytesPerInsn);
    end
  end

endmodule
