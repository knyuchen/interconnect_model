/*
   wrapper for axi_dma_wr
*/
module axi_dma_wr_wrap #
(
    // Width of AXI data bus in bits
    parameter AXI_DATA_WIDTH = 32,
    // Width of AXI address bus in bits
    parameter AXI_ADDR_WIDTH = 32,
    // Width of AXI wstrb (width of data bus in words)
    parameter AXI_STRB_WIDTH = (AXI_DATA_WIDTH/8),
    // Width of AXI ID signal
    parameter AXI_ID_WIDTH = 8,
    // Maximum AXI burst length to generate
    parameter AXI_MAX_BURST_LEN = 16,
    // Width of AXI stream interfaces in bits
    parameter AXIS_DATA_WIDTH = AXI_DATA_WIDTH,
    // Use AXI stream tkeep signal
    parameter AXIS_KEEP_ENABLE = (AXIS_DATA_WIDTH>8),
    // AXI stream tkeep signal width (words per cycle)
    parameter AXIS_KEEP_WIDTH = (AXIS_DATA_WIDTH/8),
    // Use AXI stream tlast signal
    parameter AXIS_LAST_ENABLE = 1,
    // Propagate AXI stream tid signal
    parameter AXIS_ID_ENABLE = 0,
    // AXI stream tid signal width
    parameter AXIS_ID_WIDTH = 8,
    // Propagate AXI stream tdest signal
    parameter AXIS_DEST_ENABLE = 0,
    // AXI stream tdest signal width
    parameter AXIS_DEST_WIDTH = 8,
    // Propagate AXI stream tuser signal
    parameter AXIS_USER_ENABLE = 1,
    // AXI stream tuser signal width
    parameter AXIS_USER_WIDTH = 1,
    // Width of length field
    parameter LEN_WIDTH = 9,
    // Width of tag field
    parameter TAG_WIDTH = 8,
    // Enable support for scatter/gather DMA
    // (multiple descriptors per AXI stream frame)
    parameter ENABLE_SG = 0,
    // Enable support for unaligned transfers
    parameter ENABLE_UNALIGNED = 0
)
(

    /*
     * AXI write descriptor input
     */
    input          [AXI_ADDR_WIDTH-1:0]  s_axis_write_desc_addr,
    input          [LEN_WIDTH-1:0]       s_axis_write_desc_len,
//    input          [TAG_WIDTH-1:0]       s_axis_write_desc_tag,
    input                                s_axis_write_desc_valid,
    output   logic                       s_axis_write_desc_ready,

    /*
     * AXI write descriptor status output
     */
//    output   logic [LEN_WIDTH-1:0]       m_axis_write_desc_status_len,
//    output   logic [TAG_WIDTH-1:0]       m_axis_write_desc_status_tag,
//    output   logic [AXIS_ID_WIDTH-1:0]   m_axis_write_desc_status_id,
//    output   logic [AXIS_DEST_WIDTH-1:0] m_axis_write_desc_status_dest,
//    output   logic [AXIS_USER_WIDTH-1:0] m_axis_write_desc_status_user,
    output   logic                       m_axis_write_desc_status_valid,

    /*
     * AXI stream write data input
     */
    input          [AXIS_DATA_WIDTH-1:0] s_axis_write_data_tdata,
//    input          [AXIS_KEEP_WIDTH-1:0] s_axis_write_data_tkeep,
    input                                s_axis_write_data_tvalid,
    output   logic                       s_axis_write_data_tready,
    input                                s_axis_write_data_tlast,
//    input          [AXIS_ID_WIDTH-1:0]   s_axis_write_data_tid,
//    input          [AXIS_DEST_WIDTH-1:0] s_axis_write_data_tdest,
//    input          [AXIS_USER_WIDTH-1:0] s_axis_write_data_tuser,

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
    /*
     * Configuration
     */
//    input                                enable,
//    input                                abort
);

   logic enable, abort;
   assign enable = 1;
   assign abort = 0; 
/*
   logic  [AXIS_ID_WIDTH-1 : 0]  m_axi_awid, m_axi_bid;
//   assign m_axi_awid = 0;
   logic  m_axi_awlock;
   logic  [3:0]  m_axi_awcache;
   logic  [2:0]  m_axi_awprot;
*/
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
//   logic                       m_axis_write_desc_status_valid;

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
