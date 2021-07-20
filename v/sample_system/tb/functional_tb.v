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
   
    localparam C_S_AXI_DATA_WIDTH	= 64; 
    localparam C_S_AXI_ADDR_WIDTH	= 32;
    logic        [C_S_AXI_ADDR_WIDTH-1 : 0] s_axil_awaddr;
    logic        [2 : 0] s_axil_awprot;
    logic         s_axil_awvalid;
    logic  s_axil_awready;
    logic        [C_S_AXI_DATA_WIDTH-1 : 0] s_axil_wdata;
    logic        [(C_S_AXI_DATA_WIDTH/8)-1 : 0] s_axil_wstrb;
    logic         s_axil_wvalid;
    logic  s_axil_wready;
    logic [1 : 0] s_axil_bresp;
    logic  s_axil_bvalid;
    logic         s_axil_bready;
    logic        [C_S_AXI_ADDR_WIDTH-1 : 0] s_axil_araddr;
    logic        [2 : 0] s_axil_arprot;
    logic         s_axil_arvalid;
    logic  s_axil_arready;
    logic [C_S_AXI_DATA_WIDTH-1 : 0] s_axil_rdata;
    logic [1 : 0] s_axil_rresp;
    logic  s_axil_rvalid;
    logic         s_axil_rready;
   
     SL_REQ   host_req; 
     SL_RES   host_res; 
   logic  [3:0]       interrupt_out_up; 
   logic  [3:0]       interrupt_out_down;
   logic      interrupt_out;

   initial interrupt_out_up = 0;
   initial interrupt_out_down = 0;
//   assign host_res = 0;
   SL_REQ  dummy_req;
//   initial dummy_req = 0;

   logic  dummy_rst;

   initial dummy_rst = 1;

   sl_slave s1(.*, .req(host_req), .res(host_res), .rst_n(dummy_rst && rst_n));


    task initial_input ();
        begin
            s_axil_awaddr = 0;
            s_axil_awvalid =0;
            s_axil_wvalid = 0;
            s_axil_bready = 0; 
            s_axil_arvalid = 0; 
            s_axil_rready = 0;
            s_axil_wdata = 0;
            s_axil_wstrb  = '1;
            s_axil_araddr = 0;
        end
    endtask : initial_input
 
    task input_config();
        input [3:0] addr;
        input [63:0] data;
        begin
            @(negedge clk)
            s_axil_wvalid = 1;
            s_axil_awvalid = 1;
            s_axil_awaddr = {25'd0,addr,{3'b0}};
            @(negedge clk)
            s_axil_awaddr = 0;
            s_axil_wdata = data;
            @(negedge clk)
            s_axil_wvalid = 0;
            s_axil_awvalid = 0;
            s_axil_bready = 1;
            s_axil_wdata = 0;
            @(negedge clk)
            s_axil_bready = 0;
        end
    endtask : input_config
   DAP_top d1(.*);

   axi_ram_wrap arw (.*);

   clk_gen c1 (.*);

   initial begin
      initial_input();
      dummy_req = 0; 
      #(`RESET_CYCLE*`CLK_CYCLE)
      #(3*`CLK_CYCLE)
      input_config (12, 1);
// pass state
      input_config (0, {8'd31, 8'd30, 8'd29, 8'd28, 8'd27, 8'd26, 8'd25, 8'd24});
      input_config (0, {8'd23, 8'd22, 8'd21, 8'd20, 8'd19, 8'd18, 8'd17, 8'd16});
      input_config (0, {8'd15, 8'd14, 8'd13, 8'd12, 8'd11, 8'd10, 8'd9, 8'd8});
      input_config (0, {8'd7, 8'd6, 8'd5, 8'd4, 8'd3, 8'd2, 8'd1, 8'd0});
      input_config (0, 0);
// inst from cmn
      input_config (5, {32'd0, 32'd4});
      input_config (5, {42'd0, 9'd5, 13'd6});
      input_config (5, {32'd0, 32'd40});
      input_config (5, {42'd0, 9'd20, 13'd56});
      input_config (5, 0);
      input_config (5, 0);
      #(40*`CLK_CYCLE)
// program inst inside dap scratchpad
      input_config (6, {40'd0, 2'b01, 9'd5, 13'd6});  
      input_config (6, {40'd0, 2'b01, 9'd20, 13'd56});  
      input_config (6, {40'd0, 2'b11, 13'd0, 9'd20});  
      input_config (6, {40'd0, 2'b00, 9'd0, 13'd0});  
      #(40*`CLK_CYCLE)
      interrupt_out_up = 4;
      #(20*`CLK_CYCLE)
      interrupt_out_up = 0; 
// data from cmn
      input_config (7, {32'd0, 32'd4});
      input_config (7, {42'd0, 9'd5, 13'd6});
      input_config (7, {32'd0, 32'd40});
      input_config (7, {42'd0, 9'd20, 13'd56});
      input_config (7, 0);
      input_config (7, 0);
      #(40*`CLK_CYCLE)
// route state
      input_config (3, {8'd15, 8'd14, 8'd13, 8'd12, 8'd11, 8'd10, 8'd9, 8'd8});
      input_config (3, 0);
// run state
      input_config (2, {8'd7, 8'd6, 8'd5, 8'd4, 8'd3, 8'd2, 8'd1, 8'd0});
      input_config (2, 0);
// idle state
      input_config (1, {8'd31, 8'd30, 8'd29, 8'd28, 8'd27, 8'd26, 8'd25, 8'd24});
      input_config (1, 0);
// route config
      input_config (4, {48'd0, 9'd5, 3'd4, 2'd0, 1'b0, 1'b1});
// manual write
      input_config (9, {1'b1, 18'd0, 13'd6, 32'd99});
      input_config (9, 0);
// write back to cmn
      input_config (8, {32'd0, 32'd4});
      input_config (8, {42'd0, 9'd5, 13'd6});
      input_config (8, {32'd0, 32'd40});
      input_config (8, {42'd0, 9'd20, 13'd26});
      input_config (8, 0);
      input_config (8, 0);
      #(50*`CLK_CYCLE)
      interrupt_out_down = 4;
      dummy_rst = 0;
      #(2*`CLK_CYCLE)
      dummy_rst = 1;
      #(20*`CLK_CYCLE)
      interrupt_out_down = 0; 
      #(40*`CLK_CYCLE)
      $finish;
   end

endmodule
