/*
  generic AXI Lite Slave Interface

  instantiate the module

  hook up 
     slv_reg_down --> expose all register to downstream
     slv_reg_up   --> all register from downstream
     access_addr  --> addr for each access
     read_valid   --> read access 
     write_valid  --> write access
     reg_indi     --> indicate whether the register is writeable from downstream (1 mean yes)
   Revisions:
      10/09/21: First Documentation, fixed reading functionality
*/



	module AXIL_S #
	(
		parameter C_S_AXI_DATA_WIDTH	=  64, 
                          C_S_AXI_ADDR_WIDTH	=  32,
                          NUM_REGISTER          =  4
	)
	(
/*
   global stuff
*/
		input         clk,
		input         rst_n,
/*
   axil_interface
*/
		input        [C_S_AXI_ADDR_WIDTH-1 : 0] s_axil_awaddr,
		input        [2 : 0] s_axil_awprot,
		input         s_axil_awvalid,
		output logic  s_axil_awready,
		input        [C_S_AXI_DATA_WIDTH-1 : 0] s_axil_wdata,
		input        [(C_S_AXI_DATA_WIDTH/8)-1 : 0] s_axil_wstrb,
		input         s_axil_wvalid,
		output logic  s_axil_wready,
		output logic [1 : 0] s_axil_bresp,
		output logic  s_axil_bvalid,
		input         s_axil_bready,
		input        [C_S_AXI_ADDR_WIDTH-1 : 0] s_axil_araddr,
		input        [2 : 0] s_axil_arprot,
		input         s_axil_arvalid,
		output logic  s_axil_arready,
		output logic [C_S_AXI_DATA_WIDTH-1 : 0] s_axil_rdata,
		output logic [1 : 0] s_axil_rresp,
		output logic  s_axil_rvalid,
		input         s_axil_rready,
/*
   downstream interface
*/                
                output logic [NUM_REGISTER*C_S_AXI_DATA_WIDTH - 1 : 0] slv_reg_down,
                input        [NUM_REGISTER*C_S_AXI_DATA_WIDTH - 1 : 0] slv_reg_up,
		output logic [$clog2(NUM_REGISTER) - 1 : 0] access_addr,
                output logic                            read_valid,
                output logic                            write_valid,
                input        [NUM_REGISTER - 1 : 0]     reg_indi
              
	);

	// AXI4LITE signals
	logic [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_awaddr, axi_awaddr_w;
	logic  	axi_awready;
	logic  	axi_wready;
	logic [1 : 0] 	axi_bresp;
	logic  	axi_bvalid;
	logic [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_araddr, axi_araddr_w;
	logic  	axi_arready;
	logic [C_S_AXI_DATA_WIDTH-1 : 0] 	axi_rdata, axi_rdata_w;
	logic [1 : 0] 	axi_rresp;
	logic  	axi_rvalid;

	localparam ADDR_LSB = (C_S_AXI_DATA_WIDTH/32) + 1;
	localparam OPT_MEM_ADDR_BITS = $clog2(NUM_REGISTER);
	
        logic [NUM_REGISTER - 1 : 0][C_S_AXI_DATA_WIDTH-1:0]	slv_reg_int, slv_reg_int_w;
	logic [NUM_REGISTER - 1 : 0][C_S_AXI_DATA_WIDTH-1:0]	slv_reg_ext;
	logic [NUM_REGISTER - 1 : 0][C_S_AXI_DATA_WIDTH-1:0]	slv_reg_read;
        genvar pp;
        generate
           for (pp = 0; pp < NUM_REGISTER; pp = pp + 1) begin
              assign slv_reg_down[(pp+1)*C_S_AXI_DATA_WIDTH - 1 : pp*C_S_AXI_DATA_WIDTH] = slv_reg_int[pp];
              assign slv_reg_ext[pp] = slv_reg_up[(pp+1)*C_S_AXI_DATA_WIDTH - 1 : pp*C_S_AXI_DATA_WIDTH];
              assign slv_reg_read[pp] = (reg_indi[pp] == 1) ? slv_reg_ext[pp] : slv_reg_int[pp];
           end
        endgenerate


	logic	 slv_reg_rden;
	logic	 slv_reg_wren;
	logic [C_S_AXI_DATA_WIDTH-1:0]	 reg_data_out;
	integer	 byte_index;
	logic	 aw_en;

	// I/O Connections assignments

	assign s_axil_awready	= axi_awready;
	assign s_axil_wready	= axi_wready;
	assign s_axil_bresp	= axi_bresp;
	assign s_axil_bvalid	= axi_bvalid;
	assign s_axil_arready	= axi_arready;
	assign s_axil_rdata	= axi_rdata;
	assign s_axil_rresp	= axi_rresp;
	assign s_axil_rvalid	= axi_rvalid;

		// SIDM - Begin
      
       logic  axi_awready_w, aw_en_w;

       always_comb begin
          axi_awready_w = axi_awready;
          aw_en_w = aw_en;
/*
  awready triggered by awvalid & wvalid
*/
	  if (~axi_awready && s_axil_awvalid && s_axil_wvalid && aw_en) begin
             axi_awready_w = 1;
             aw_en_w = 0;
          end
/*
  awready reset by bready bvalid handshaking
*/
          else if (s_axil_bready && axi_bvalid) begin
             aw_en_w = 1;
             axi_awready_w = 0;
          end
          else begin
             axi_awready_w = 0;
          end
       end


	always_ff @(posedge clk or negedge rst_n)
	begin
	  if (rst_n == 1'b0)
	    begin
	      axi_awready <= 1'b0;
	      aw_en <= 1'b1;
	    end 
	  else
	    begin  
               axi_awready <= axi_awready_w;
               aw_en <= aw_en_w; 
	    end 
	end       

/*
   awaddr latched by awvalid & wvalid
*/
     assign axi_awaddr_w =  (~axi_awready && s_axil_awvalid && s_axil_wvalid && aw_en) ? s_axil_awaddr : axi_awaddr;

	always_ff @(posedge clk or negedge rst_n)
	begin
	  if (rst_n == 1'b0)
	    begin
	      axi_awaddr <= 0;
	    end 
	  else
	    begin    
              axi_awaddr <= axi_awaddr_w;
	    end 
	end       


      logic axi_wready_w;
/*
   wready triggerred by wvalid & awvalid
*/
    assign axi_wready_w = (~axi_wready && s_axil_wvalid && s_axil_awvalid && aw_en ) ? 1 : 0;


	always_ff @(posedge clk or negedge rst_n)
	begin
	  if (rst_n == 1'b0)
	    begin
	      axi_wready <= 1'b0;
	    end 
	  else
	    begin  
              axi_wready <= axi_wready_w; 
	    end 
	end       
/*
   slv_reg_wren: double handshaking
*/
	assign slv_reg_wren = axi_wready && s_axil_wvalid && axi_awready && s_axil_awvalid;

	


       logic [OPT_MEM_ADDR_BITS - 1 : 0]  wreg_index, rreg_index, access_addr_w;
/*
   index is generate the same cycle as double handshaking
*/
       assign wreg_index = axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB];
       assign rreg_index = axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB];
/*
   Downstream output, nothing to do with interface handshaking
*/
       always_comb begin
          access_addr_w = access_addr;
          if (slv_reg_wren == 1) access_addr_w = wreg_index;
          else if (slv_reg_rden == 1) access_addr_w = rreg_index;
       end
/*
   Writing Internal Registers
*/
       always_comb begin
          slv_reg_int_w = slv_reg_int;
          if (slv_reg_wren == 1) begin
	     for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 ) begin
	       if ( s_axil_wstrb[byte_index] == 1 ) begin
	          slv_reg_int_w[wreg_index][(byte_index*8) +: 8] = s_axil_wdata[(byte_index*8) +: 8];
	       end  
             end
          end
       end



        logic axi_bvalid_w, axi_bresp_w;
        always_comb begin
            axi_bvalid_w = axi_bvalid;
            axi_bresp_w = axi_bresp;
/*
   bvalid triggered by double handshaking
*/
	      if (axi_awready && s_axil_awvalid && ~axi_bvalid && axi_wready && s_axil_wvalid)
	        begin
	          axi_bvalid_w = 1'b1;
	          axi_bresp_w  = 2'b0; // 'OKAY' response 
	        end                   // work error responses in future
	      else
	        begin
/*
   bvalid is reset by bready bvalid handshaking
*/
	          if (s_axil_bready && axi_bvalid) 
	            begin
	              axi_bvalid_w = 1'b0; 
	            end  
	        end
        end

	always_ff @(posedge clk or negedge rst_n)
	begin
	  if (rst_n == 1'b0)
	    begin
	      axi_bvalid  <= 0;
	      axi_bresp   <= 2'b0;
              slv_reg_int <= 0;
	    end 
	  else
	    begin   
              axi_bvalid <= axi_bvalid_w;
              axi_bresp <= axi_bresp_w;
              slv_reg_int <= slv_reg_int_w;
	    end
	end   


        logic axi_arready_w;
  
        always_comb begin
           axi_arready_w = axi_arready;
           axi_araddr_w = axi_araddr;
/*
   arready triggered by arvalid
*/
	      if (~axi_arready && s_axil_arvalid)
	        begin
	          axi_arready_w = 1'b1;
	          axi_araddr_w  = s_axil_araddr;
	        end
/*
   arready only high for one cycle
*/
	      else
	        begin
	          axi_arready_w = 1'b0;
	        end
        end


	always_ff @(posedge clk or negedge rst_n)
	begin
	  if (rst_n == 1'b0)
	    begin
	      axi_arready <= 1'b0;
	      axi_araddr  <= 0;
	    end 
	  else
	    begin   
              axi_arready <= axi_arready_w;
              axi_araddr <= axi_araddr_w;
	    end 
	end       


        logic axi_rvalid_w, axi_rresp_w;

        always_comb begin
           axi_rvalid_w = axi_rvalid;
           axi_rresp_w = axi_rresp;
/*
   rvalid triggered by arready, arvalid handshaking
   araddr latched by arvalid
*/
	   if (axi_arready && s_axil_arvalid && ~axi_rvalid)
	      begin
	          axi_rvalid_w = 1'b1;
	          axi_rresp_w  = 2'b0; // 'OKAY' response
	        end   
/*
   rvalid reset by rvalid, rready handshaking
*/
	      else if (axi_rvalid && s_axil_rready)
	        begin
	          axi_rvalid_w = 1'b0;
	        end                
        end
   
	always_ff @(posedge clk or negedge rst_n)
	begin
	  if (rst_n == 1'b0)
	    begin
	      axi_rvalid <= 0;
	      axi_rresp  <= 0;
	    end 
	  else
	    begin 
              axi_rvalid <= axi_rvalid_w;
              axi_rresp  <= axi_rresp_w;  
	    end
	end    

	


	always_ff @(posedge clk or negedge rst_n) begin
		if (rst_n == 1'b0) begin
                        access_addr  <= 0;
                        read_valid   <= 0;
                        read_valid   <= 0;
		end
		else begin
                        access_addr <= access_addr_w;
                        read_valid   <= slv_reg_rden;
                        write_valid   <= slv_reg_wren;
		end
	end
/*
  slv_reg_rden is arready arvalid handshaking
*/	
	assign slv_reg_rden = axi_arready & s_axil_arvalid & ~axi_rvalid;
        assign reg_data_out = slv_reg_read[rreg_index];
/*
  make sure rdata goes out the same cycle as rvalid
*/
        assign axi_rdata_w = (slv_reg_rden) ? reg_data_out : axi_rdata;
	always_ff @(posedge clk or negedge rst_n)
	begin
	  if (rst_n == 1'b0)
	    begin
	      axi_rdata  <= 0;
	    end 
	  else
	    begin   
              axi_rdata <= axi_rdata_w;
	    end
	end    


	endmodule
