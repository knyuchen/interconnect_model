/*
   wrapper for axi_dma_wr
*/
module axi_dma_wr_wrap #
(
    parameter AXI_DATA_WIDTH = 32,
    parameter AXI_ADDR_WIDTH = 32,
    parameter AXI_ID_WIDTH = 8,
    parameter LEN_WIDTH = 9,
    parameter AXIS_DATA_WIDTH = AXI_DATA_WIDTH,
    parameter AXI_STRB_WIDTH = (AXI_DATA_WIDTH/8)
)
(

    /*
     * AXI write descriptor input
     */
    input          [AXI_ADDR_WIDTH-1:0]  s_axis_write_desc_addr,
    input          [LEN_WIDTH-1:0]       s_axis_write_desc_len,
    input                                s_axis_write_desc_valid,
    output   logic                       s_axis_write_desc_ready,
    output   logic                       m_axis_write_desc_status_valid,

    /*
     * AXI stream write data input
     */
    input          [AXIS_DATA_WIDTH-1:0] s_axis_write_data_tdata,
    input                                s_axis_write_data_tvalid,
    output   logic                       s_axis_write_data_tready,
    input                                s_axis_write_data_tlast,

    /*
     * AXI master interface
     */
    output   logic [AXI_ID_WIDTH-1:0]    m_axi_awid,
    output   logic [AXI_ADDR_WIDTH-1:0]  m_axi_awaddr,
    output   logic [7:0]                 m_axi_awlen,
    output   logic [2:0]                 m_axi_awsize,
    output   logic [1:0]                 m_axi_awburst,
    output   logic                       m_axi_awlock,
    output   logic [3:0]                 m_axi_awcache,
    output   logic [2:0]                 m_axi_awprot,
    output   logic                       m_axi_awvalid,
    input                                m_axi_awready,
    output   logic [AXI_DATA_WIDTH-1:0]  m_axi_wdata,
    output   logic [AXI_STRB_WIDTH-1:0]  m_axi_wstrb,
    output   logic                       m_axi_wlast,
    output   logic                       m_axi_wvalid,
    input                                m_axi_wready,
    input          [AXI_ID_WIDTH-1:0]    m_axi_bid,
    input          [1:0]                 m_axi_bresp,
    input                                m_axi_bvalid,
    output   logic                       m_axi_bready,

    input                                clk,
    input                                rst_n
);

    localparam AXIS_KEEP_ENABLE = (AXIS_DATA_WIDTH>8);
    localparam AXI_MAX_BURST_LEN = 16;
    localparam AXIS_KEEP_WIDTH = (AXIS_DATA_WIDTH/8);
    localparam AXIS_LAST_ENABLE = 1;
    localparam AXIS_ID_ENABLE = 0;
    localparam AXIS_ID_WIDTH = 8;
    localparam AXIS_DEST_ENABLE = 0;
    localparam AXIS_DEST_WIDTH = 8;
    localparam AXIS_USER_ENABLE = 1;
    localparam AXIS_USER_WIDTH = 1;
    localparam TAG_WIDTH = 8;
    localparam ENABLE_SG = 0;
    localparam ENABLE_UNALIGNED = 0;
   logic enable, abort;
   assign enable = 1;
   assign abort = 0; 
   logic  rst;
 
   assign rst = ~rst_n;
   logic          [AXIS_KEEP_WIDTH-1:0] s_axis_write_data_tkeep;
   logic          [AXIS_ID_WIDTH-1:0]   s_axis_write_data_tid;
   logic          [AXIS_DEST_WIDTH-1:0] s_axis_write_data_tdest;
   logic          [AXIS_USER_WIDTH-1:0] s_axis_write_data_tuser;

   assign s_axis_write_data_tkeep = '1;
   assign s_axis_write_data_tid = 0;
   assign s_axis_write_data_tdest = 0;
   assign s_axis_write_data_tuser = 0;

   logic          [TAG_WIDTH-1:0]       s_axis_write_desc_tag;
   logic [LEN_WIDTH-1:0]       m_axis_write_desc_status_len;
   logic [TAG_WIDTH-1:0]       m_axis_write_desc_status_tag;
   logic [AXIS_ID_WIDTH-1:0]   m_axis_write_desc_status_id;
   logic [AXIS_DEST_WIDTH-1:0] m_axis_write_desc_status_dest;
   logic [AXIS_USER_WIDTH-1:0] m_axis_write_desc_status_user;

   assign s_axis_write_desc_tag = 0;
   axi_dma_wr #(
      .AXI_DATA_WIDTH(AXI_DATA_WIDTH),
      .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
      .AXI_STRB_WIDTH(AXI_STRB_WIDTH),
      .AXI_ID_WIDTH(AXI_ID_WIDTH),
      .AXI_MAX_BURST_LEN(AXI_MAX_BURST_LEN),
      .AXIS_DATA_WIDTH(AXI_DATA_WIDTH),
      .AXIS_KEEP_ENABLE(AXIS_KEEP_ENABLE),
      .AXIS_KEEP_WIDTH(AXIS_KEEP_WIDTH),
      .AXIS_LAST_ENABLE(AXIS_LAST_ENABLE),
      .AXIS_ID_ENABLE(AXIS_ID_ENABLE),
      .AXIS_ID_WIDTH(AXIS_ID_WIDTH),
      .AXIS_DEST_ENABLE(AXIS_DEST_ENABLE),
      .AXIS_DEST_WIDTH(AXIS_DEST_WIDTH),
      .AXIS_USER_ENABLE(AXIS_USER_ENABLE),
      .AXIS_USER_WIDTH(AXIS_USER_WIDTH),
      .LEN_WIDTH(LEN_WIDTH),
      .TAG_WIDTH(TAG_WIDTH),
      .ENABLE_SG(ENABLE_SG),
      .ENABLE_UNALIGNED(ENABLE_UNALIGNED)
   ) axi_dma_wr (.*);
endmodule
