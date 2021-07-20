module dma_wr #
(
    parameter AXI_DATA_WIDTH = 32,
    parameter AXI_ADDR_WIDTH = 32,
    parameter AXI_ID_WIDTH = 8,
    parameter CONFIG_LEN_WIDTH = 9,
    parameter OUTSTANDING_COUNT = 2,
    parameter AXIS_DATA_WIDTH = AXI_DATA_WIDTH,
    parameter AXI_STRB_WIDTH = (AXI_DATA_WIDTH/8),
    parameter LEN_WIDTH = CONFIG_LEN_WIDTH + $clog2(AXI_DATA_WIDTH/8)
)
(


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
   /*
    * next stage
    */
   output   logic                         ready,
   input                                  valid_in,
   input           [AXI_DATA_WIDTH - 1 : 0]  data_in,
    /*
     * Configuration
     */
    input                                 config_valid,
    output   logic                        config_ready,
    output   logic                        config_empty,
    input          [CONFIG_LEN_WIDTH-1:0] config_len, 
    input          [AXI_ADDR_WIDTH-1:0]   config_addr, 
    /*
     * misc
     */
    input                                clk,
    input                                rst_n
);
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
    
    logic          [AXI_ADDR_WIDTH-1:0]  s_axis_write_desc_addr;
    logic          [LEN_WIDTH-1:0]       s_axis_write_desc_len;
    logic                                s_axis_write_desc_valid;
    logic                       s_axis_write_desc_ready;
    logic                       m_axis_write_desc_status_valid;

    logic          [AXIS_DATA_WIDTH-1:0] s_axis_write_data_tdata;
    logic                                s_axis_write_data_tvalid;
    logic                       s_axis_write_data_tready;
    logic                                s_axis_write_data_tlast;
   


    logic                            stream_config_valid;
    logic  [CONFIG_LEN_WIDTH - 1 : 0] stream_config_len;

    axi_dma_wr_wrap #(
        .AXI_DATA_WIDTH(AXI_DATA_WIDTH),
        .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
        .AXI_ID_WIDTH(AXI_ID_WIDTH),
        .LEN_WIDTH(LEN_WIDTH)
    ) adrw (.*);

    axis_m # (
       .WIDTH(AXIS_DATA_WIDTH),
       .LEN_WIDTH(CONFIG_LEN_WIDTH)
    )asm(
       .*,
       .m_axis_tdata(s_axis_write_data_tdata),
       .m_axis_tvalid(s_axis_write_data_tvalid),
       .m_axis_tready(s_axis_write_data_tready),
       .m_axis_tlast(s_axis_write_data_tlast),
       .config_valid(stream_config_valid),
       .config_len(stream_config_len)
    );
   
   logic   [AXI_ADDR_WIDTH + CONFIG_LEN_WIDTH - 1 : 0]  wdata, rdata;
   logic                    push, pop, full, empty, valid;
   logic                    al_full, al_empty, ack, flush;
  
   assign flush = 0;
 
   d0fifo #(
      .WIDTH(AXI_ADDR_WIDTH + CONFIG_LEN_WIDTH),
      .SIZE(OUTSTANDING_COUNT),
      .FULL(1),
      .EMPTY(1),
      .AL_FULL(0),
      .AL_EMPTY(0),
      .ACK(0),
      .VALID(1),
      .PEEK(1),
      .FLUSH(0)
   )d1(.*);
   logic state, state_w;

   localparam  WAIT_DMA = 0, WAIT_STREAM = 1;

   logic [$clog2(AXI_DATA_WIDTH/8) - 1 : 0] len_zero;
   assign len_zero = '0;

   assign s_axis_write_desc_addr = rdata[AXI_ADDR_WIDTH + CONFIG_LEN_WIDTH - 1 : CONFIG_LEN_WIDTH];
   assign s_axis_write_desc_len  = {rdata[CONFIG_LEN_WIDTH - 1 : 0], len_zero};
   assign s_axis_write_desc_valid = valid == 1 && state == WAIT_DMA;
   assign push = config_valid;
   assign pop  = s_axis_write_desc_ready == 1 && s_axis_write_desc_valid == 1 && state == WAIT_DMA;
   assign wdata = {config_addr, config_len};
   assign config_ready = ~full;
   assign config_empty = empty && state == WAIT_DMA;

   assign stream_config_valid = s_axis_write_desc_valid;
   assign stream_config_len = s_axis_write_desc_len >>> $clog2(AXI_DATA_WIDTH/8) ;


   always_comb begin
      state_w = state;
      if (state == WAIT_DMA) begin
         if (s_axis_write_desc_ready == 1 && s_axis_write_desc_valid == 1) begin
            state_w = WAIT_STREAM;
         end 
      end
      else begin
         if (m_axis_write_desc_status_valid == 1) begin
            state_w = WAIT_DMA;
         end
      end
   end 

   always_ff @ (posedge clk or negedge rst_n) begin
      if (rst_n == 0) begin
         state <= WAIT_DMA;
      end
      else begin
         state <= state_w;
      end
   end




endmodule
