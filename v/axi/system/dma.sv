module dma #(
    parameter AXI_ADDR_WIDTH = 32,
    parameter AXI_DATA_WIDTH = 32,
    parameter AXI_ID_WIDTH = 8,
    parameter OUTSTANDING_COUNT = 2,
    parameter TOP_LEN_WIDTH  = 32,
    parameter FIX_LEN        = 64,
    parameter AXI_STRB_WIDTH = (AXI_DATA_WIDTH/8),
    parameter CONFIG_LEN_WIDTH = 9
)
(
/*
    global stuff
*/
    input                                  clk,
    input                                  rst_n,
/*
   from top decoder
*/    
    output   logic                         read_done,
    input                                  read_start,
    input                                  top_read_valid,
    input          [TOP_LEN_WIDTH - 1 : 0] top_read_len,
    input          [AXI_ADDR_WIDTH-1:0]    top_read_addr,

    output   logic                         write_done,
    input                                  write_start,
    input                                  top_write_valid,
    input          [TOP_LEN_WIDTH - 1 : 0] top_write_len,
    input          [AXI_ADDR_WIDTH-1:0]    top_write_addr,
/*
    to internal input stage
*/
    input                                 input_ready,
    output   logic [AXI_DATA_WIDTH-1:0]   data_out,
    output   logic                        valid_out,
    output   logic                        last_out,
/*
    from internal output stage
*/
   output   logic                         output_ready,
   input                                  valid_in,
   input           [AXI_DATA_WIDTH - 1 : 0]  data_in,
/*
    axi read
*/
    output   logic [AXI_ID_WIDTH-1:0]     m_axi_arid,
    output   logic [AXI_ADDR_WIDTH-1:0]   m_axi_araddr,
    output   logic [7:0]                  m_axi_arlen,
    output   logic [2:0]                  m_axi_arsize,
    output   logic [1:0]                  m_axi_arburst,
    output   logic                        m_axi_arlock,
    output   logic [3:0]                  m_axi_arcache,
    output   logic [2:0]                  m_axi_arprot,
    output   logic                        m_axi_arvalid,
    input                                 m_axi_arready,
    input          [AXI_ID_WIDTH-1:0]     m_axi_rid,
    input          [AXI_DATA_WIDTH-1:0]   m_axi_rdata,
    input          [1:0]                  m_axi_rresp,
    input                                 m_axi_rlast,
    input                                 m_axi_rvalid,
    output   logic                        m_axi_rready,
/*
   axi write
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
    output   logic                       m_axi_bready
);
    logic                         read_config_valid;
    logic                                  read_config_ready;
    logic                                  read_config_empty;
    logic [CONFIG_LEN_WIDTH-1:0]  read_config_len; 
    logic [AXI_ADDR_WIDTH-1:0]    read_config_addr; 
    
    logic                         write_config_valid;
    logic                                  write_config_ready;
    logic                                  write_config_empty;
    logic [CONFIG_LEN_WIDTH-1:0]  write_config_len; 
    logic [AXI_ADDR_WIDTH-1:0]    write_config_addr; 

    dma_control # (.AXI_ADDR_WIDTH (AXI_ADDR_WIDTH),
                   .AXI_DATA_WIDTH (AXI_DATA_WIDTH),
                   .TOP_LEN_WIDTH(TOP_LEN_WIDTH),
                   .FIX_LEN(FIX_LEN),
                   .CONFIG_LEN_WIDTH(CONFIG_LEN_WIDTH)) dc1 (.*);
    dma_rd #(.AXI_DATA_WIDTH(AXI_DATA_WIDTH),
             .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
             .AXI_ID_WIDTH(AXI_ID_WIDTH),
             .CONFIG_LEN_WIDTH(CONFIG_LEN_WIDTH),
             .OUTSTANDING_COUNT(OUTSTANDING_COUNT))
             dr1 (.config_valid(read_config_valid),
                  .config_ready(read_config_ready),
                  .config_empty(read_config_empty),
                  .config_len(read_config_len),
                  .config_addr (read_config_addr),
                  .ready(input_ready),
                  .*);
    dma_wr #(.AXI_DATA_WIDTH(AXI_DATA_WIDTH),
             .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
             .AXI_ID_WIDTH(AXI_ID_WIDTH),
             .CONFIG_LEN_WIDTH(CONFIG_LEN_WIDTH),
             .OUTSTANDING_COUNT(OUTSTANDING_COUNT))
             dw1 (.config_valid(write_config_valid),
                  .config_ready(write_config_ready),
                  .config_empty(write_config_empty),
                  .config_len(write_config_len),
                  .config_addr (write_config_addr),
                  .ready(output_ready),
                  .*);
endmodule
