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
		// Users to add parameters here

		// User parameters ends
		// Do not modify the parameters beyond this line

		// Width of S_AXI data bus
		parameter C_S_AXI_DATA_WIDTH	= 64, 
                          C_S_AXI_ADDR_WIDTH	= 32,
                          NUM_REGISTER          = `LITE_REG_NUM
	)
	(
		// Users to add ports here

		// SIDM - Begin
		
		
		// User ports ends
		// Do not modify the ports beyond this line

		// Global Clock Signal
		input         S_AXI_ACLK,
		// Global Reset Signal. This Signal is Active LOW
		input         S_AXI_ARESETN,
		// Write address (issued by master, acceped by Slave)
		input        [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
		// Write channel Protection type. This signal indicates the
    		// privilege and security level of the transaction, and whether
    		// the transaction is a data access or an instruction access.
		input        [2 : 0] S_AXI_AWPROT,
		// Write address valid. This signal indicates that the master signaling
    		// valid write address and control information.
		input         S_AXI_AWVALID,
		// Write address ready. This signal indicates that the slave is ready
    		// to accept an address and associated control signals.
		output logic  S_AXI_AWREADY,
		// Write data (issued by master, acceped by Slave) 
		input        [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA,
		// Write strobes. This signal indicates which byte lanes hold
    		// valid data. There is one write strobe bit for each eight
    		// bits of the write data bus.    
		input        [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
		// Write valid. This signal indicates that valid write
    		// data and strobes are available.
		input         S_AXI_WVALID,
		// Write ready. This signal indicates that the slave
    		// can accept the write data.
		output logic  S_AXI_WREADY,
		// Write response. This signal indicates the status
    		// of the write transaction.
		output logic [1 : 0] S_AXI_BRESP,
		// Write response valid. This signal indicates that the channel
    		// is signaling a valid write response.
		output logic  S_AXI_BVALID,
		// Response ready. This signal indicates that the master
    		// can accept a write response.
		input         S_AXI_BREADY,
		// Read address (issued by master, acceped by Slave)
		input        [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
		// Protection type. This signal indicates the privilege
    		// and security level of the transaction, and whether the
    		// transaction is a data access or an instruction access.
		input        [2 : 0] S_AXI_ARPROT,
		// Read address valid. This signal indicates that the channel
    		// is signaling valid read address and control information.
		input         S_AXI_ARVALID,
		// Read address ready. This signal indicates that the slave is
    		// ready to accept an address and associated control signals.
		output logic  S_AXI_ARREADY,
		// Read data (issued by slave)
		output logic [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA,
		// Read response. This signal indicates the status of the
    		// read transfer.
		output logic [1 : 0] S_AXI_RRESP,
		// Read valid. This signal indicates that the channel is
    		// signaling the required read data.
		output logic  S_AXI_RVALID,
		// Read ready. This signal indicates that the master can
    		// accept the read data and response information.
		input         S_AXI_RREADY,
                
                output logic [NUM_REGISTER*C_S_AXI_DATA_WIDTH - 1 : 0] slv_reg_down,
                input        [NUM_REGISTER*C_S_AXI_DATA_WIDTH - 1 : 0] slv_reg_up,
		output logic [C_S_AXI_ADDR_WIDTH-1 : 0] access_addr,
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

	// Example-specific design signals
	// local parameter for addressing 32 bit / 64 bit C_S_AXI_DATA_WIDTH
	// ADDR_LSB is used for addressing 32/64 bit registers/memories
	// ADDR_LSB = 2 for 32 bits (n downto 2)
	// ADDR_LSB = 3 for 64 bits (n downto 3)
	localparam ADDR_LSB = (C_S_AXI_DATA_WIDTH/32) + 1;
	localparam OPT_MEM_ADDR_BITS = $clog2(NUM_REGISTER);
	//----------------------------------------------
	//-- Signals for user logic register space example
	//------------------------------------------------
	//-- Number of Slave Registers 12
	logic [NUM_REGISTER - 1 : 0][C_S_AXI_DATA_WIDTH-1:0]	slv_reg_int, slv_reg_int_w;
	logic [NUM_REGISTER - 1 : 0][C_S_AXI_DATA_WIDTH-1:0]	slv_reg_ext, slv_reg_ext_w;
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
	logic [C_S_AXI_DATA_WIDTH-1:0]	 reg_data_out, reg_data_out_w;
	integer	 byte_index;
	logic	 aw_en;

	// I/O Connections assignments

	assign S_AXI_AWREADY	= axi_awready;
	assign S_AXI_WREADY	= axi_wready;
	assign S_AXI_BRESP	= axi_bresp;
	assign S_AXI_BVALID	= axi_bvalid;
	assign S_AXI_ARREADY	= axi_arready;
	assign S_AXI_RDATA	= axi_rdata;
	assign S_AXI_RRESP	= axi_rresp;
	assign S_AXI_RVALID	= axi_rvalid;

		// SIDM - Begin
      
       logic  axi_awready_w, aw_en_w;

       always_comb begin
          axi_awready_w = axi_awready;
          aw_en_w = aw_en;
	  if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en) begin
             axi_awready_w = 1;
             aw_en_w = 0;
          end
          else if (S_AXI_BREADY && axi_bvalid) begin
             aw_en_w = 1;
             axi_awready_w = 0;
          end
          else begin
             axi_awready_w = 0;
          end
       end


	always_ff @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN)
	begin
	  if (S_AXI_ARESETN == 1'b0)
	    begin
	      axi_awready <= 1'b0;
	      aw_en <= 1'b1;
	    end 
	  else
	    begin  
               axi_awready <= axi_awready_w;
               aw_en <= aw_en_w; 
/* 
	      if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
	        begin
	          // slave is ready to accept write address when 
	          // there is a valid write address and write data
	          // on the write address and data bus. This design 
	          // expects no outstanding transactions. 
	          axi_awready <= 1'b1;
	          aw_en <= 1'b0;

	        end
	        else if (S_AXI_BREADY && axi_bvalid)
	            begin
	              aw_en <= 1'b1;
	              axi_awready <= 1'b0;
	            end
	      else           
	        begin
	          axi_awready <= 1'b0;
	        end
*/
	    end 
	end       

	// Implement axi_awaddr latching
	// This process is used to latch the address when both 
	// S_AXI_AWVALID and S_AXI_WVALID are valid. 

     assign axi_awaddr_w =  (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en) ? S_AXI_AWADDR : axi_awaddr;

	always_ff @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN)
	begin
	  if (S_AXI_ARESETN == 1'b0)
	    begin
	      axi_awaddr <= 0;
	    end 
	  else
	    begin    
              axi_awaddr <= axi_awaddr_w;
/*
	      if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
	        begin
	          // Write Address latching 
	          axi_awaddr <= S_AXI_AWADDR;
	        end
*/
	    end 
	end       

	// Implement axi_wready generation
	// axi_wready is asserted for one S_AXI_ACLK clock cycle when both
	// S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_wready is 
	// de-asserted when reset is low. 

      logic axi_wready_w;
    assign axi_wready_w = (~axi_wready && S_AXI_WVALID && S_AXI_AWVALID && aw_en ) ? 1 : 0;


	always_ff @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN)
	begin
	  if (S_AXI_ARESETN == 1'b0)
	    begin
	      axi_wready <= 1'b0;
	    end 
	  else
	    begin  
              axi_wready <= axi_wready_w; 
/* 
	      if (~axi_wready && S_AXI_WVALID && S_AXI_AWVALID && aw_en )
	        begin
	          // slave is ready to accept write data when 
	          // there is a valid write address and write data
	          // on the write address and data bus. This design 
	          // expects no outstanding transactions. 
	          axi_wready <= 1'b1;
	        end
	      else
	        begin
	          axi_wready <= 1'b0;
	        end
*/
	    end 
	end       

	// Implement memory mapped register select and write logic generation
	// The write data is accepted and written to memory mapped registers when
	// axi_awready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted. Write strobes are used to
	// select byte enables of slave registers while writing.
	// These registers are cleared when reset (active low) is applied.
	// Slave register write enable is asserted when valid address and data are available
	// and the slave is ready to accept the write address and write data.
	assign slv_reg_wren = axi_wready && S_AXI_WVALID && axi_awready && S_AXI_AWVALID;

	


       logic [OPT_MEM_ADDR_BITS - 1 : 0]  wreg_index, rreg_index;
       assign wreg_index = axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB];
       assign rreg_index = axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB];

       always_comb begin
          slv_reg_int_w = slv_reg_int;
          if (slv_reg_wren == 1) begin
	     for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 ) begin
	       if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	          slv_reg_int_w[wreg_index][(byte_index*8) +: 8] = S_AXI_WDATA[(byte_index*8) +: 8];
	       end  
             end
          end
       end


	// Implement write response logic generation
	// The write response and response valid signals are asserted by the slave 
	// when axi_wready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted.  
	// This marks the acceptance of address and indicates the status of 
	// write transaction.

        logic axi_bvalid_w, axi_bresp_w;
        always_comb begin
            axi_bvalid_w = axi_bvalid;
            axi_bresp_w = axi_bresp;
	      if (axi_awready && S_AXI_AWVALID && ~axi_bvalid && axi_wready && S_AXI_WVALID)
	        begin
	          // indicates a valid write response is available
	          axi_bvalid_w = 1'b1;
	          axi_bresp_w  = 2'b0; // 'OKAY' response 
	        end                   // work error responses in future
	      else
	        begin
	          if (S_AXI_BREADY && axi_bvalid) 
	            //check if bready is asserted while bvalid is high) 
	            //(there is a possibility that bready is always asserted high)   
	            begin
	              axi_bvalid_w = 1'b0; 
	            end  
	        end
        end

	always_ff @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN)
	begin
	  if (S_AXI_ARESETN == 1'b0)
	    begin
	      axi_bvalid  <= 0;
	      axi_bresp   <= 2'b0;
	    end 
	  else
	    begin   
              axi_bvalid <= axi_bvalid_w;
              axi_bresp <= axi_bresp_w;
/* 
	      if (axi_awready && S_AXI_AWVALID && ~axi_bvalid && axi_wready && S_AXI_WVALID)
	        begin
	          // indicates a valid write response is available
	          axi_bvalid <= 1'b1;
	          axi_bresp  <= 2'b0; // 'OKAY' response 
	        end                   // work error responses in future
	      else
	        begin
	          if (S_AXI_BREADY && axi_bvalid) 
	            //check if bready is asserted while bvalid is high) 
	            //(there is a possibility that bready is always asserted high)   
	            begin
	              axi_bvalid <= 1'b0; 
	            end  
	        end
*/
	    end
	end   

	// Implement axi_arready generation
	// axi_arready is asserted for one S_AXI_ACLK clock cycle when
	// S_AXI_ARVALID is asserted. axi_awready is 
	// de-asserted when reset (active low) is asserted. 
	// The read address is also latched when S_AXI_ARVALID is 
	// asserted. axi_araddr is reset to zero on reset assertion.

        logic axi_arready_w;
  
        always_comb begin
           axi_arready_w = axi_arready;
           axi_araddr_w = axi_araddr;
	      if (~axi_arready && S_AXI_ARVALID)
	        begin
	          // indicates that the slave has acceped the valid read address
	          axi_arready_w = 1'b1;
	          // Read address latching
	          axi_araddr_w  = S_AXI_ARADDR;
	        end
	      else
	        begin
	          axi_arready_w = 1'b0;
	        end
        end


	always_ff @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN)
	begin
	  if (S_AXI_ARESETN == 1'b0)
	    begin
	      axi_arready <= 1'b0;
	      axi_araddr  <= 0;
	    end 
	  else
	    begin   
              axi_arready <= axi_arready_w;
              axi_araddr <= axi_araddr_w;
/* 
	      if (~axi_arready && S_AXI_ARVALID)
	        begin
	          // indicates that the slave has acceped the valid read address
	          axi_arready <= 1'b1;
	          // Read address latching
	          axi_araddr  <= S_AXI_ARADDR;
	        end
	      else
	        begin
	          axi_arready <= 1'b0;
	        end
*/
	    end 
	end       

	// Implement axi_arvalid generation
	// axi_rvalid is asserted for one S_AXI_ACLK clock cycle when both 
	// S_AXI_ARVALID and axi_arready are asserted. The slave registers 
	// data are available on the axi_rdata bus at this instance. The 
	// assertion of axi_rvalid marks the validity of read data on the 
	// bus and axi_rresp indicates the status of read transaction.axi_rvalid 
	// is deasserted on reset (active low). axi_rresp and axi_rdata are 
	// cleared to zero on reset (active low). 

        logic axi_rvalid_w, axi_rresp_w;

        always_comb begin
           axi_rvalid_w = axi_rvalid;
           axi_rresp_w = axi_rresp;
	   if (axi_arready && S_AXI_ARVALID && ~axi_rvalid)
	      begin
	          // Valid read data is available at the read data bus
	          axi_rvalid_w = 1'b1;
	          axi_rresp_w  = 2'b0; // 'OKAY' response
	        end   
	      else if (axi_rvalid && S_AXI_RREADY)
	        begin
	          // Read data is accepted by the master
	          axi_rvalid_w = 1'b0;
	        end                
        end
   
	always_ff @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN)
	begin
	  if (S_AXI_ARESETN == 1'b0)
	    begin
	      axi_rvalid <= 0;
	      axi_rresp  <= 0;
	    end 
	  else
	    begin 
              axi_rvalid <= axi_rvalid_w;
              axi_rresp  <= axi_rresp_w;  
/* 
	      if (axi_arready && S_AXI_ARVALID && ~axi_rvalid)
	        begin
	          // Valid read data is available at the read data bus
	          axi_rvalid <= 1'b1;
	          axi_rresp  <= 2'b0; // 'OKAY' response
	        end   
	      else if (axi_rvalid && S_AXI_RREADY)
	        begin
	          // Read data is accepted by the master
	          axi_rvalid <= 1'b0;
	        end    
*/            
	    end
	end    

	
        logic  [OPT_MEM_ADDR_BITS - 1 : 0]  access_addr_w;


	always_ff @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (S_AXI_ARESETN == 1'b0) begin
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
	assign slv_reg_rden = axi_arready & S_AXI_ARVALID & ~axi_rvalid;
        assign reg_data_out_w = slv_reg_read[rreg_index];

	// Output register or memory read data
        assign axi_rdata_w = (slv_reg_rden) ? reg_data_out : axi_rdata;
	always_ff @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN)
	begin
	  if (S_AXI_ARESETN == 1'b0)
	    begin
	      axi_rdata  <= 0;
              reg_data_out <= 0;
	    end 
	  else
	    begin   
              reg_data_out <= reg_data_out_w; 
              axi_rdata <= axi_rdata_w;
	      // When there is a valid read address (S_AXI_ARVALID) with 
	      // acceptance of read address by the slave (axi_arready), 
	      // output the read dada
/* 
	      if (slv_reg_rden)
	        begin
	          axi_rdata <= reg_data_out;     // register read data
	        end   
*/
	    end
	end    

	// Add user logic here
	// User logic ends

	endmodule
