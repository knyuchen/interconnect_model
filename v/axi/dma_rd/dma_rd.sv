/*
   dma + axis_s + command dispatcher
   Revisions
     10/12/21:
       First Documentation, might want to make some "len" bitwidth parameterized in the future
*/
module dma_rd #
(
    parameter AXI_DATA_WIDTH = 32,
    parameter AXI_ADDR_WIDTH = 32,
    parameter AXI_ID_WIDTH = 8,
    // from dma controller, LEN per data
    parameter CONFIG_LEN_WIDTH = 9,
    parameter OUTSTANDING_COUNT = 2,
    parameter AXIS_DATA_WIDTH = AXI_DATA_WIDTH,
    parameter AXI_STRB_WIDTH = (AXI_DATA_WIDTH/8),
    // LEN per byte
    parameter LEN_WIDTH = CONFIG_LEN_WIDTH + $clog2(AXI_DATA_WIDTH/8)
)
(
    /*
       to next stage from axis_s
    */

    input                                 ready,
    output   logic [AXI_DATA_WIDTH-1:0]   data_out,
    output   logic                        valid_out,
    output   logic                        last_out,
    
    /*
     * AXI master interface
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
    input                                 clk,
    input                                 rst_n
);
/*
   Interface to axi_dma_rd_wrap, command dispatch
*/ 
    logic          [AXI_ADDR_WIDTH-1:0]  s_axis_read_desc_addr;
    logic          [LEN_WIDTH-1:0]       s_axis_read_desc_len;
    logic                                s_axis_read_desc_valid;
    logic                                s_axis_read_desc_ready;
    logic                                m_axis_read_desc_status_valid;
/*
   Interface to axis_s
*/    
    logic [AXIS_DATA_WIDTH-1:0]          m_axis_read_data_tdata;
    logic                                m_axis_read_data_tvalid;
    logic                                m_axis_read_data_tready;
    logic                                m_axis_read_data_tlast;

    axi_dma_rd_wrap #(
        .AXI_DATA_WIDTH(AXI_DATA_WIDTH),
        .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
        .AXI_ID_WIDTH(AXI_ID_WIDTH),
        .LEN_WIDTH(LEN_WIDTH)
    ) adrw (.*);
   
    axis_s #(
        .WIDTH(AXI_DATA_WIDTH)
    ) axs (
        .*,
        .s_axis_tdata(m_axis_read_data_tdata),
        .s_axis_tvalid(m_axis_read_data_tvalid),
        .s_axis_tready(m_axis_read_data_tready),
        .s_axis_tlast(m_axis_read_data_tlast)
    ); 
    
   logic   [AXI_ADDR_WIDTH + CONFIG_LEN_WIDTH - 1 : 0]  wdata, rdata;
   logic                    push, pop, full, empty, valid;
   logic                    al_full, al_empty, ack, flush;
  
   assign flush = 0;
/*
   Buffer for command dispatch
   PEEK is on because this is a "valid high regardless handshaking"
*/ 
   d0fifo #(
      .WIDTH(AXI_ADDR_WIDTH + CONFIG_LEN_WIDTH),
      .SIZE(OUTSTANDING_COUNT),
      .FULL(1),
      .EMPTY(1),
      .AL_FULL(OUTSTANDING_COUNT),
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

   assign s_axis_read_desc_addr = rdata[AXI_ADDR_WIDTH + CONFIG_LEN_WIDTH - 1 : CONFIG_LEN_WIDTH];
// extending len from len per data to len per byte
   assign s_axis_read_desc_len  = {rdata[CONFIG_LEN_WIDTH - 1 : 0], len_zero};
// valid is always peeking in WAIT_DMA state
   assign s_axis_read_desc_valid = valid == 1 && state == WAIT_DMA;
   assign push = config_valid;
/*
   If there is PEEK, then pop is better done with handshaking (not necessary though, just to be safe)
*/
   assign pop  = s_axis_read_desc_ready == 1 && s_axis_read_desc_valid == 1 && state == WAIT_DMA;
   assign wdata = {config_addr, config_len};
/*
   This implementation is common practice, sometimes ready is used to pop the next data
   If (pop == 1) is not added, then a situation will happen when full == 1, push == 1
   when pop == 1, new data should be expected, but because push == 1 --> full == 1 
   ready is still 0, no new data will come and the previous stage will hang
*/
   assign config_ready = ~full || pop == 1;
/*
   This implementation is important to avoid empty but still processing
*/
   assign config_empty = empty && state == WAIT_DMA;


   always_comb begin
      state_w = state;
      // waiting DMA to accept the command (handshaking)
      if (state == WAIT_DMA) begin
         if (s_axis_read_desc_ready == 1 && s_axis_read_desc_valid == 1) begin
            state_w = WAIT_STREAM;
         end 
      end
      // waiting DMA to finish the transaction
      else begin
         if (m_axis_read_desc_status_valid == 1) begin
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
