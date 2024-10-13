module hsv_core_top_flat #(
    parameter logic [31:0] HART_ID         = 0,
    parameter int          FETCH_BURST_LEN = 4
) (
    input logic clk_core,
    input logic rst_core_n,

    // Unused imem write interfaces
    // This is required by Platform Designer

    input  logic        imem_awready,
    output logic        imem_awvalid,
    output logic [ 7:0] imem_awid,
    output logic [ 7:0] imem_awlen,
    output logic [ 2:0] imem_awsize,
    output logic [ 1:0] imem_awburst,
    output logic [ 2:0] imem_awprot,
    output logic [31:0] imem_awaddr,

    input  logic        imem_wready,
    output logic        imem_wvalid,
    output logic [31:0] imem_wdata,
    output logic        imem_wlast,
    output logic [ 3:0] imem_wstrb,

    output logic       imem_bready,
    input  logic       imem_bvalid,
    input  logic [7:0] imem_bid,
    input  logic [1:0] imem_bresp,

    input  logic        imem_arready,
    output logic        imem_arvalid,
    output logic [ 7:0] imem_arid,
    output logic [ 7:0] imem_arlen,
    output logic [ 2:0] imem_arsize,
    output logic [ 1:0] imem_arburst,
    output logic [ 2:0] imem_arprot,
    output logic [31:0] imem_araddr,

    output logic        imem_rready,
    input  logic        imem_rvalid,
    input  logic [ 7:0] imem_rid,
    input  logic [31:0] imem_rdata,
    input  logic [ 1:0] imem_rresp,
    input  logic        imem_rlast,

    input  logic        dmem_awready,
    output logic        dmem_awvalid,
    output logic [ 7:0] dmem_awid,
    output logic [ 7:0] dmem_awlen,
    output logic [ 2:0] dmem_awsize,
    output logic [ 1:0] dmem_awburst,
    output logic [ 2:0] dmem_awprot,
    output logic [31:0] dmem_awaddr,

    input  logic        dmem_wready,
    output logic        dmem_wvalid,
    output logic [31:0] dmem_wdata,
    output logic        dmem_wlast,
    output logic [ 3:0] dmem_wstrb,

    output logic       dmem_bready,
    input  logic       dmem_bvalid,
    input  logic [7:0] dmem_bid,
    input  logic [1:0] dmem_bresp,

    input  logic        dmem_arready,
    output logic        dmem_arvalid,
    output logic [ 7:0] dmem_arid,
    output logic [ 7:0] dmem_arlen,
    output logic [ 2:0] dmem_arsize,
    output logic [ 1:0] dmem_arburst,
    output logic [ 2:0] dmem_arprot,
    output logic [31:0] dmem_araddr,

    output logic        dmem_rready,
    input  logic        dmem_rvalid,
    input  logic [ 7:0] dmem_rid,
    input  logic [31:0] dmem_rdata,
    input  logic [ 1:0] dmem_rresp,
    input  logic        dmem_rlast,

    input logic irq_core
);

  axib_if imem ();
  axil_if dmem ();

  assign imem_awid = '0;
  assign imem_awlen = '0;
  assign imem_awsize = '0;
  assign imem_awprot = '0;
  assign imem_awaddr = '0;
  assign imem_awburst = '0;
  assign imem_awvalid = 0;

  assign imem_wdata = '0;
  assign imem_wlast = 0;
  assign imem_wstrb = '0;
  assign imem_wvalid = 0;

  assign imem_bready = 0;

  assign imem_arid = imem.s.arid;
  assign imem_arlen = imem.s.arlen;
  assign imem_arsize = imem.s.arsize;
  assign imem_araddr = imem.s.araddr;
  assign imem_arprot = 3'b011;
  assign imem_arburst = imem.s.arburst;
  assign imem_arvalid = imem.s.arvalid;
  assign imem.s.arready = imem_arready;

  assign imem_rready = imem.s.rready;
  assign imem.s.rid = imem_rid;
  assign imem.s.rdata = imem_rdata;
  assign imem.s.rlast = imem_rlast;
  assign imem.s.rresp = imem_rresp;
  assign imem.s.rvalid = imem_rvalid;

  assign dmem_arid = '0;
  assign dmem_arlen = '0;
  assign dmem_arsize = 3'b010;
  assign dmem_araddr = dmem.s.araddr;
  assign dmem_arprot = 3'b010;
  assign dmem_arburst = 2'b01;
  assign dmem_arvalid = dmem.s.arvalid;
  assign dmem.s.arready = dmem_arready;

  assign dmem_awid = '0;
  assign dmem_awlen = '0;
  assign dmem_awsize = 3'b010;
  assign dmem_awaddr = dmem.s.awaddr;
  assign dmem_awprot = 3'b010;
  assign dmem_awburst = 2'b01;
  assign dmem_awvalid = dmem.s.awvalid;
  assign dmem.s.awready = dmem_awready;

  assign dmem_wdata = dmem.s.wdata;
  assign dmem_wlast = 1;
  assign dmem_wstrb = dmem.s.wstrb;
  assign dmem_wvalid = dmem.s.wvalid;
  assign dmem.s.wready = dmem_wready;

  assign dmem_rready = dmem.s.rready;
  assign dmem.s.rdata = dmem_rdata;
  assign dmem.s.rresp = dmem_rresp;
  assign dmem.s.rvalid = dmem_rvalid;

  assign dmem_bready = dmem.s.bready;
  assign dmem.s.bresp = dmem_bresp;
  assign dmem.s.bvalid = dmem_bvalid;

  hsv_core_top #(
      .HART_ID(HART_ID),
      .FETCH_BURST_LEN(FETCH_BURST_LEN)
  ) core (
      .clk_core,
      .rst_core_n,
      .imem(imem.m),
      .dmem(dmem.m),
      .irq_core(0),
      .*
  );

endmodule
