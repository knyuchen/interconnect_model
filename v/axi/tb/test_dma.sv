module test ();

    
    parameter AXI_DATA_WIDTH = 32;
    parameter AXIS_DATA_WIDTH = 32;
    parameter AXI_ADDR_WIDTH = 32;
    parameter AXI_STRB_WIDTH = (AXI_DATA_WIDTH/8);
    parameter LEN_WIDTH = 9;
    parameter AXI_ID_WIDTH = 8;

/*
    unused signals start
*/

    logic [3:0]  s_axi_awcache, s_axi_arcache;
    logic [2:0]  s_axi_awprot, s_axi_arprot;
    logic        s_axi_awlock, s_axi_arlock;

    logic [AXI_ID_WIDTH - 1 : 0]  s_axi_awid, s_axi_bid, s_axi_arid, s_axi_rid;

   logic  [AXI_ID_WIDTH - 1 : 0]  m_axi_arid, m_axi_rid;
   logic   m_axi_arlock;
   logic  [3:0]  m_axi_arcache;
   logic  [2:0]  m_axi_arprot;
   
   logic  [AXI_ID_WIDTH-1 : 0]  m_axi_awid, m_axi_bid;
   logic  m_axi_awlock;
   logic  [3:0]  m_axi_awcache;
   logic  [2:0]  m_axi_awprot;
/*
    unused signals end
*/
  
   logic m_axis_read_desc_status_valid;
   logic m_axis_write_desc_status_valid;

    logic          [AXI_ADDR_WIDTH-1:0]  s_axis_write_desc_addr;
    logic          [LEN_WIDTH-1:0]       s_axis_write_desc_len;
    logic                                s_axis_write_desc_valid;
    logic                                s_axis_write_desc_ready;

    logic          [AXIS_DATA_WIDTH-1:0] s_axis_write_data_tdata;
    logic                                s_axis_write_data_tvalid;
    logic                                s_axis_write_data_tready;
    logic                                s_axis_write_data_tlast;
    
    logic          [AXI_ID_WIDTH-1:0]    m_axi_awid;
    logic          [AXI_ADDR_WIDTH-1:0]  m_axi_awaddr;
    logic          [7:0]                 m_axi_awlen;
    logic          [2:0]                 m_axi_awsize;
    logic          [1:0]                 m_axi_awburst;
    
    logic                                m_axi_awvalid;
    logic                                m_axi_awready;
    logic          [AXI_DATA_WIDTH-1:0]  m_axi_wdata;
    logic          [AXI_STRB_WIDTH-1:0]  m_axi_wstrb;
    logic                                m_axi_wlast;
    logic                                m_axi_wvalid;
    logic                                m_axi_wready;
    
    logic          [1:0]                 m_axi_bresp;
    logic                                m_axi_bvalid;
    logic                                m_axi_bready;

    logic                                clk;
    logic                                rst_n;

    logic          [AXI_ADDR_WIDTH-1:0]  s_axis_read_desc_addr;
    logic          [LEN_WIDTH-1:0]       s_axis_read_desc_len;
    logic                                s_axis_read_desc_valid;
    logic                                 s_axis_read_desc_ready;
    
    logic           [AXIS_DATA_WIDTH-1:0] m_axis_read_data_tdata;
    logic                                 m_axis_read_data_tvalid;
    logic                                m_axis_read_data_tready;
    logic                                 m_axis_read_data_tlast;

    logic           [AXI_ADDR_WIDTH-1:0]  m_axi_araddr;
    logic           [7:0]                 m_axi_arlen;
    logic           [2:0]                 m_axi_arsize;
    logic           [1:0]                 m_axi_arburst;
    
    logic                                 m_axi_arvalid;
    logic                                m_axi_arready;
    
    logic          [AXI_DATA_WIDTH-1:0]  m_axi_rdata;
    logic          [1:0]                 m_axi_rresp;
    logic                                m_axi_rlast;
    logic                                m_axi_rvalid;
    logic                                 m_axi_rready;
    

    parameter DATA_WIDTH = 32;
    parameter ADDR_WIDTH = 32;
    parameter STRB_WIDTH = (DATA_WIDTH/8);
   
   logic            [ADDR_WIDTH-1:0]  s_axi_awaddr;
   logic            [7:0]             s_axi_awlen;
   logic            [2:0]             s_axi_awsize;
   logic            [1:0]             s_axi_awburst;
   logic                              s_axi_awvalid;
   logic                               s_axi_awready;

   logic            [DATA_WIDTH-1:0]  s_axi_wdata;
   logic            [STRB_WIDTH-1:0]  s_axi_wstrb;
   logic                              s_axi_wlast;
   logic                              s_axi_wvalid;
   logic                               s_axi_wready;

   logic             [1:0]             s_axi_bresp;
   logic                               s_axi_bvalid;
   logic                              s_axi_bready;

   logic            [ADDR_WIDTH-1:0]  s_axi_araddr;
   logic            [7:0]             s_axi_arlen;
   logic            [2:0]             s_axi_arsize;
   logic            [1:0]             s_axi_arburst;
   logic                              s_axi_arvalid;
   logic                               s_axi_arready;

   logic             [DATA_WIDTH-1:0]  s_axi_rdata;
   logic             [1:0]             s_axi_rresp;
   logic                               s_axi_rlast;
   logic                               s_axi_rvalid;
   logic                              s_axi_rready;

   assign s_axi_awaddr = m_axi_awaddr;
   assign s_axi_awlen = m_axi_awlen;
   assign s_axi_awsize = m_axi_awsize;
   assign s_axi_awburst = m_axi_awburst;
   assign s_axi_awvalid = m_axi_awvalid;
   assign m_axi_awready = s_axi_awready;

   assign s_axi_wdata = m_axi_wdata;
   assign s_axi_wstrb = m_axi_wstrb;
   assign s_axi_wlast = m_axi_wlast;
   assign s_axi_wvalid = m_axi_wvalid;
   assign m_axi_wready = s_axi_wready;

   assign m_axi_bresp = s_axi_bresp;
   assign m_axi_bvalid = s_axi_bvalid;
   assign s_axi_bready = m_axi_bready;

   assign s_axi_araddr = m_axi_araddr;
   assign s_axi_arlen = m_axi_arlen;
   assign s_axi_arsize = m_axi_arsize;
   assign s_axi_arburst = m_axi_arburst;
   assign s_axi_arvalid = m_axi_arvalid;
   assign m_axi_arready = s_axi_arready;

   assign m_axi_rdata = s_axi_rdata;
   assign m_axi_rresp = s_axi_rresp;
   assign m_axi_rlast = s_axi_rlast;
   assign m_axi_rvalid = s_axi_rvalid;
   assign s_axi_rready = m_axi_rready;

   stream_aux_master sam (
      .tdata(s_axis_write_data_tdata),
      .tvalid(s_axis_write_data_tvalid),
      .enable(1'b1),
      .total_num({25'b0, s_axis_write_desc_len[8:2]}),
      .tlast(s_axis_write_data_tlast),
      .tready(s_axis_write_data_tready),
      .*
   );

   assign m_axis_read_data_tready = 1;

   axi_dma_rd_wrap adrw (.*);
   axi_dma_wr_wrap adww (.*);
   axi_ram_wrap arw (.*);

   clk_gen c1 (.*);


    initial   s_axis_write_desc_addr = 0;
    initial   s_axis_write_desc_len = 0;
    initial   s_axis_write_desc_valid = 0;
    initial   s_axis_read_desc_addr = 0; 
    initial   s_axis_read_desc_len = 0; 
    initial   s_axis_read_desc_valid = 0; 
   initial begin
//   $readmemb("/afs/eecs.umich.edu/vlsida/user/knyuchen/interconnect_model/python/random_number_gen/random.bin", arw/axi_ram0/mem);
      #(`RESET_CYCLE*`CLK_CYCLE)
      #(10*`CLK_CYCLE)
/*
      @(negedge clk)
         s_axis_write_desc_addr = {30'd1, 2'b0};
         s_axis_write_desc_len  = 100;
         s_axis_write_desc_valid = 1;
      @(negedge clk)
         s_axis_write_desc_valid = 0;
      #(40*`CLK_CYCLE)  
*/
      @(negedge clk)
         s_axis_read_desc_addr = {30'd2, 2'b0};
         s_axis_read_desc_len  = 80;
         s_axis_read_desc_valid = 1;
      @(negedge clk)
         s_axis_read_desc_valid = 0;
      #(40*`CLK_CYCLE)  
      $finish;
   end

endmodule
