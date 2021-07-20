/*
   wrapper for axi_dma_rd
*/

module axi_dma_rd_wrap #
(
    parameter AXI_DATA_WIDTH = 32,
    parameter AXI_ADDR_WIDTH = 32,
    parameter AXI_ID_WIDTH = 8,
    parameter LEN_WIDTH    = 9,
    parameter AXIS_DATA_WIDTH = AXI_DATA_WIDTH
)
(

    /*
     * AXI read descriptor input
     */
    input          [AXI_ADDR_WIDTH-1:0]  s_axis_read_desc_addr,
    input          [LEN_WIDTH-1:0]       s_axis_read_desc_len,
    input                                s_axis_read_desc_valid,
    output   logic                       s_axis_read_desc_ready,

    output   logic                       m_axis_read_desc_status_valid,

    output   logic [AXIS_DATA_WIDTH-1:0] m_axis_read_data_tdata,
    output   logic                       m_axis_read_data_tvalid,
    input                                m_axis_read_data_tready,
    output   logic                       m_axis_read_data_tlast,

    /*
     * AXI master interface
     */
    output   logic [AXI_ID_WIDTH-1:0]    m_axi_arid,
    output   logic [AXI_ADDR_WIDTH-1:0]  m_axi_araddr,
    output   logic [7:0]                 m_axi_arlen,
    output   logic [2:0]                 m_axi_arsize,
    output   logic [1:0]                 m_axi_arburst,
    output   logic                       m_axi_arlock,
    output   logic [3:0]                 m_axi_arcache,
    output   logic [2:0]                 m_axi_arprot,
    output   logic                       m_axi_arvalid,
    input                                m_axi_arready,
    input          [AXI_ID_WIDTH-1:0]    m_axi_rid,
    input          [AXI_DATA_WIDTH-1:0]  m_axi_rdata,
    input          [1:0]                 m_axi_rresp,
    input                                m_axi_rlast,
    input                                m_axi_rvalid,
    output   logic                       m_axi_rready,

    /*
     * Configuration
     */
    input                                clk,
    input                                rst_n
);
    localparam AXI_STRB_WIDTH = (AXI_DATA_WIDTH/8);
    localparam AXI_MAX_BURST_LEN = 16;
    localparam AXIS_KEEP_ENABLE = (AXIS_DATA_WIDTH>8);
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
   
   logic [AXIS_ID_WIDTH - 1 : 0]   m_axis_read_data_tid;
   logic [AXIS_DEST_WIDTH - 1 : 0] m_axis_read_data_tdest;
   logic [AXIS_USER_WIDTH - 1 : 0] m_axis_read_data_tuser;
   logic [AXIS_KEEP_WIDTH - 1 : 0] m_axis_read_data_tkeep;


   logic          [TAG_WIDTH-1:0]       s_axis_read_desc_tag;
   logic          [AXIS_ID_WIDTH-1:0]   s_axis_read_desc_id;
   logic          [AXIS_DEST_WIDTH-1:0] s_axis_read_desc_dest;
   logic          [AXIS_USER_WIDTH-1:0] s_axis_read_desc_user;

   assign s_axis_read_desc_tag = 0;
   assign s_axis_read_desc_id = 0;
   assign s_axis_read_desc_dest = 0;
   assign s_axis_read_desc_user = 0;

   logic [TAG_WIDTH-1:0]       m_axis_read_desc_status_tag;
//   logic                       m_axis_read_desc_status_valid;

   logic  rst;
 
   assign rst = ~rst_n;

   logic enable;
   
   assign enable = 1;

   axi_dma_rd #(
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
   ) axi_dma_r0 (.*);
endmodule
