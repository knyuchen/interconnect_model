/*
   wrapper for axi_ram, also reverse reset polarity
*/

module axi_ram_wrap #
(
    // Width of data bus in bits
    parameter DATA_WIDTH = 32,
    // Width of address bus in bits
    parameter ADDR_WIDTH = 32,
    parameter EFF_ADDR_WIDTH = 8,
    // Width of wstrb (width of data bus in words)
    parameter STRB_WIDTH = (DATA_WIDTH/8),
    // Width of ID signal
    parameter ID_WIDTH = 8,
    // Extra pipeline register on output   logic
    parameter PIPELINE_OUTPUT = 0,
    parameter FILE_NUM = 0
)
(
   input            [ID_WIDTH-1:0]    s_axi_awid,
   input            [ADDR_WIDTH-1:0]  s_axi_awaddr,
   input            [7:0]             s_axi_awlen,
   input            [2:0]             s_axi_awsize,
   input            [1:0]             s_axi_awburst,
   input                              s_axi_awlock,
   input            [3:0]             s_axi_awcache,
   input            [2:0]             s_axi_awprot,

   input                              s_axi_awvalid,
   output   logic                     s_axi_awready,
   input            [DATA_WIDTH-1:0]  s_axi_wdata,
   input            [STRB_WIDTH-1:0]  s_axi_wstrb,
   input                              s_axi_wlast,
   input                              s_axi_wvalid,
   output   logic                     s_axi_wready,
   output   logic   [ID_WIDTH-1:0]    s_axi_bid,
   output   logic   [1:0]             s_axi_bresp,
   output   logic                     s_axi_bvalid,
   input                              s_axi_bready,

   input            [ID_WIDTH-1:0]    s_axi_arid,
   input            [ADDR_WIDTH-1:0]  s_axi_araddr,
   input            [7:0]             s_axi_arlen,
   input            [2:0]             s_axi_arsize,
   input            [1:0]             s_axi_arburst,
   input                              s_axi_arlock,
   input            [3:0]             s_axi_arcache,
   input            [2:0]             s_axi_arprot,
   input                              s_axi_arvalid,
   output   logic                     s_axi_arready,
   output   logic   [ID_WIDTH-1:0]    s_axi_rid,
   output   logic   [DATA_WIDTH-1:0]  s_axi_rdata,
   output   logic   [1:0]             s_axi_rresp,
   output   logic                     s_axi_rlast,
   output   logic                     s_axi_rvalid,
   input                              s_axi_rready,
   input                          clk,
   input                          rst_n
);

    // Width of ID signal
/*
   localparam ID_WIDTH = 8;

   logic  [ID_WIDTH -1 : 0]  s_axi_awid, s_axi_bid;
   logic  [ID_WIDTH -1 : 0]  s_axi_arid, s_axi_rid;

   assign s_axi_awid = 0;
   assign s_axi_arid = 0;

   logic  s_axi_awlock, s_axi_arlock;
   logic  [3:0]  s_axi_awcache, s_axi_arcache;
   logic  [2:0]  s_axi_awprot, s_axi_arprot;
*/
   logic  rst;
 
   assign rst = ~rst_n;

   axi_ram # (
      .DATA_WIDTH(DATA_WIDTH),
      .ADDR_WIDTH(ADDR_WIDTH),
      .EFF_ADDR_WIDTH(EFF_ADDR_WIDTH),
      .STRB_WIDTH(STRB_WIDTH),
      .ID_WIDTH(ID_WIDTH),
      .PIPELINE_OUTPUT(PIPELINE_OUTPUT),
      .FILE_NUM(FILE_NUM)
   ) axi_ram0 (.*); 

endmodule
