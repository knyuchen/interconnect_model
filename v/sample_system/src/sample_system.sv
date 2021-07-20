module sample_system #(
    parameter AXI_DATA_WIDTH = 32,
    parameter AXI_ADDR_WIDTH = 32,
    parameter AXI_ID_WIDTH = 8,
    parameter AXIL_DATA_WIDTH	= 64, 
    parameter NUM_REGISTER          =   4,
    parameter TOP_LEN_WIDTH    = 20,
    parameter FIX_LEN          = 64,
    parameter CONFIG_LEN_WIDTH = 9,
    parameter OUTSTANDING_COUNT = 2,
    parameter AXI_STRB_WIDTH = (AXI_DATA_WIDTH/8),
    parameter AXIL_ADDR_WIDTH	= AXI_ADDR_WIDTH
)
(  
    input             clk,
    input             rst_n,
// AXI READ Master    
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
// AXI WRITE Master    
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
// axi-lite slave		
    input        [AXIL_ADDR_WIDTH-1 : 0] s_axil_awaddr,
    input        [2 : 0] s_axil_awprot,
    input         s_axil_awvalid,
    output logic  s_axil_awready,
    input        [AXIL_DATA_WIDTH-1 : 0] s_axil_wdata,
    input        [(AXIL_DATA_WIDTH/8)-1 : 0] s_axil_wstrb,
    input         s_axil_wvalid,
    output logic  s_axil_wready,
    output logic [1 : 0] s_axil_bresp,
    output logic  s_axil_bvalid,
    input         s_axil_bready,
    input        [AXIL_ADDR_WIDTH-1 : 0] s_axil_araddr,
    input        [2 : 0] s_axil_arprot,
    input         s_axil_arvalid,
    output logic  s_axil_arready,
    output logic [AXIL_DATA_WIDTH-1 : 0] s_axil_rdata,
    output logic [1 : 0] s_axil_rresp,
    output logic  s_axil_rvalid,
    input         s_axil_rready
);

  logic [NUM_REGISTER*AXIL_DATA_WIDTH - 1 : 0] slv_reg_down;
  logic [NUM_REGISTER*AXIL_DATA_WIDTH - 1 : 0] slv_reg_up;
  logic [$clog2(NUM_REGISTER) - 1 : 0] access_addr;
  logic                            read_valid;
  logic                            write_valid;
  logic        [NUM_REGISTER - 1 : 0]     reg_indi;

  assign reg_indi = 4'b1000;
 
   AXIL_S #(.NUM_REGISTER(NUM_REGISTER)) axil (.*);

  logic [NUM_REGISTER*AXIL_DATA_WIDTH - 1 : 0] reg_down;
   assign reg_down = slv_reg_down;
   logic                             read_start;
   logic                             read_restart;
   logic                             top_read_valid;
   logic     [TOP_LEN_WIDTH - 1 : 0] top_read_len;
   logic     [AXI_ADDR_WIDTH-1:0]    top_read_addr;

   logic                             write_start;
   logic                             write_restart;
   logic                             top_write_valid;
   logic     [TOP_LEN_WIDTH - 1 : 0] top_write_len;
   logic     [AXI_ADDR_WIDTH-1:0]    top_write_addr;

   top_decoder #(
      .AXIL_DATA_WIDTH(AXIL_DATA_WIDTH),
       .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
      .NUM_REGISTER(NUM_REGISTER),
      .TOP_LEN_WIDTH(TOP_LEN_WIDTH)    
   ) td1 (.*);
    logic                               read_config_valid;
    logic                                  read_config_ready;
    logic                                  read_config_empty;
    logic       [CONFIG_LEN_WIDTH-1:0]  read_config_len; 
    logic       [AXI_ADDR_WIDTH-1:0]    read_config_addr; 
    
    logic                               write_config_valid;
    logic                                  write_config_ready;
    logic                                  write_config_empty;
    logic       [CONFIG_LEN_WIDTH-1:0]  write_config_len; 
    logic       [AXI_ADDR_WIDTH-1:0]    write_config_addr; 

    logic                               read_done;
    logic                               write_done;
   dma_control #(
      .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
      .TOP_LEN_WIDTH(TOP_LEN_WIDTH),
      .FIX_LEN(FIX_LEN),
      .CONFIG_LEN_WIDTH(CONFIG_LEN_WIDTH)
   ) dc1 (.*);
    logic                         out_ready;
    logic [AXI_DATA_WIDTH-1:0]   data_out;
    logic                        valid_out;
    logic                        last_out;

    logic                         in_ready;
    logic                                  valid_in;
    logic          [AXI_DATA_WIDTH - 1 : 0]  data_in;

    dma_rd #(
       .AXI_DATA_WIDTH(AXI_DATA_WIDTH),
       .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
       .AXI_ID_WIDTH(AXI_ID_WIDTH),
       .CONFIG_LEN_WIDTH(CONFIG_LEN_WIDTH),
       .OUTSTANDING_COUNT(OUTSTANDING_COUNT)      
    ) dr1 (
       .*,
       .config_valid(read_config_valid),
       .config_ready(read_config_ready),
       .config_empty(read_config_empty),
       .config_len(read_config_len),
       .config_addr(read_config_addr),
       .ready(out_ready)
    );
    dma_wr #(
       .AXI_DATA_WIDTH(AXI_DATA_WIDTH),
       .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
       .AXI_ID_WIDTH(AXI_ID_WIDTH),
       .CONFIG_LEN_WIDTH(CONFIG_LEN_WIDTH),
       .OUTSTANDING_COUNT(OUTSTANDING_COUNT)      
    ) dw1 (
       .*,
       .config_valid(write_config_valid),
       .config_ready(write_config_ready),
       .config_empty(write_config_empty),
       .config_len(write_config_len),
       .config_addr(write_config_addr),
       .ready(in_ready)
    );
   logic   [AXI_DATA_WIDTH - 1 : 0]  wdata, rdata;
   logic                    push, pop, full, empty, valid;
   logic                    al_full, al_empty, ack, flush;
   assign wdata = data_out;
   assign data_in = rdata;
   assign push = valid_out;
   assign out_ready = ~full;
   assign pop = in_ready;
   assign valid_in = valid;
     
   assign flush = 0;
 
   d0fifo #(
      .WIDTH(AXI_DATA_WIDTH),
      .SIZE(8),
      .FULL(1),
      .EMPTY(1),
      .AL_FULL(0),
      .AL_EMPTY(0),
      .ACK(0),
      .VALID(1),
      .PEEK(0),
      .FLUSH(0)
   )d1(.*);
endmodule
