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
*/



	module AXIL_S #
	(
		parameter AXIL_DATA_WIDTH	= 64, 
                          AXIL_ADDR_WIDTH	= 32,
                          NUM_REGISTER          = 12 
	)
	(
		input         clk,
		input         rst_n,
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
		input         s_axil_rready,
                
                output logic [NUM_REGISTER*AXIL_DATA_WIDTH - 1 : 0] slv_reg_down,
                input        [NUM_REGISTER*AXIL_DATA_WIDTH - 1 : 0] slv_reg_up,
		output logic [$clog2(NUM_REGISTER) - 1 : 0] access_addr,
                output logic                            read_valid,
                output logic                            write_valid,
                input        [NUM_REGISTER - 1 : 0]     reg_indi
              
	);

	// AXI4LITE signals
	logic [AXIL_ADDR_WIDTH-1 : 0] 	axi_awaddr, axi_awaddr_w;
	logic  	axi_awready;
	logic  	axi_wready;
	logic [1 : 0] 	axi_bresp;
	logic  	axi_bvalid;
	logic [AXIL_ADDR_WIDTH-1 : 0] 	axi_araddr, axi_araddr_w;
	logic  	axi_arready;
	logic [AXIL_DATA_WIDTH-1 : 0] 	axi_rdata, axi_rdata_w;
	logic [1 : 0] 	axi_rresp;
	logic  	axi_rvalid;

	localparam ADDR_LSB = (AXIL_DATA_WIDTH/32) + 1;
	localparam OPT_MEM_ADDR_BITS = $clog2(NUM_REGISTER);
	logic [NUM_REGISTER - 1 : 0][AXIL_DATA_WIDTH-1:0]	slv_reg_int, slv_reg_int_w;
	logic [NUM_REGISTER - 1 : 0][AXIL_DATA_WIDTH-1:0]	slv_reg_ext;
	logic [NUM_REGISTER - 1 : 0][AXIL_DATA_WIDTH-1:0]	slv_reg_read;
        genvar pp;
        generate
           for (pp = 0; pp < NUM_REGISTER; pp = pp + 1) begin
              assign slv_reg_down[(pp+1)*AXIL_DATA_WIDTH - 1 : pp*AXIL_DATA_WIDTH] = slv_reg_int[pp];
              assign slv_reg_ext[pp] = slv_reg_up[(pp+1)*AXIL_DATA_WIDTH - 1 : pp*AXIL_DATA_WIDTH];
              assign slv_reg_read[pp] = (reg_indi[pp] == 1) ? slv_reg_ext[pp] : slv_reg_int[pp];
           end
        endgenerate


	logic	 slv_reg_rden;
	logic	 slv_reg_wren;
	logic [AXIL_DATA_WIDTH-1:0]	 reg_data_out, reg_data_out_w;
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
	  if (~axi_awready && s_axil_awvalid && s_axil_wvalid && aw_en) begin
             axi_awready_w = 1;
             aw_en_w = 0;
          end
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

	assign slv_reg_wren = axi_wready && s_axil_wvalid && axi_awready && s_axil_awvalid;

	


       logic [OPT_MEM_ADDR_BITS - 1 : 0]  wreg_index, rreg_index, access_addr_w;
       assign wreg_index = axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB];
       assign rreg_index = axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB];

       always_comb begin
          access_addr_w = access_addr;
          if (slv_reg_wren == 1) access_addr_w = wreg_index;
          else if (slv_reg_rden == 1) access_addr_w = rreg_index;
       end

       always_comb begin
          slv_reg_int_w = slv_reg_int;
          if (slv_reg_wren == 1) begin
	     for ( byte_index = 0; byte_index <= (AXIL_DATA_WIDTH/8)-1; byte_index = byte_index+1 ) begin
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
	      if (axi_awready && s_axil_awvalid && ~axi_bvalid && axi_wready && s_axil_wvalid)
	        begin
	          // indicates a valid write response is available
	          axi_bvalid_w = 1'b1;
	          axi_bresp_w  = 2'b0; // 'OKAY' response 
	        end                   // work error responses in future
	      else
	        begin
	          if (s_axil_bready && axi_bvalid) 
	            //check if bready is asserted while bvalid is high) 
	            //(there is a possibility that bready is always asserted high)   
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
	      if (~axi_arready && s_axil_arvalid)
	        begin
	          // indicates that the slave has acceped the valid read address
	          axi_arready_w = 1'b1;
	          // Read address latching
	          axi_araddr_w  = s_axil_araddr;
	        end
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
	   if (axi_arready && s_axil_arvalid && ~axi_rvalid)
	      begin
	          // Valid read data is available at the read data bus
	          axi_rvalid_w = 1'b1;
	          axi_rresp_w  = 2'b0; // 'OKAY' response
	        end   
	      else if (axi_rvalid && s_axil_rready)
	        begin
	          // Read data is accepted by the master
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
	// Implement memory mapped register select and read logic generation
	// Slave register read enable is asserted when valid address is available
	// and the slave is ready to accept the read address.
	assign slv_reg_rden = axi_arready & s_axil_arvalid & ~axi_rvalid;
        assign reg_data_out_w = slv_reg_read[rreg_index];

	// Output register or memory read data
        assign axi_rdata_w = (slv_reg_rden) ? reg_data_out : axi_rdata;
	always_ff @(posedge clk or negedge rst_n)
	begin
	  if (rst_n == 1'b0)
	    begin
	      axi_rdata  <= 0;
              reg_data_out <= 0;
	    end 
	  else
	    begin   
              reg_data_out <= reg_data_out_w; 
              axi_rdata <= axi_rdata_w;
	    end
	end    

	// Add user logic here
	// User logic ends

	endmodule
