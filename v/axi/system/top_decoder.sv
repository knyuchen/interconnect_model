module top_decoder #(
   parameter   AXIL_DATA_WIDTH  = 64,
   parameter   AXI_ADDR_WIDTH  = 32,
   parameter   NUM_REGISTER     = 4, 
   parameter   TOP_LEN_WIDTH     = 20 
) (
   input [AXIL_DATA_WIDTH*NUM_REGISTER - 1 : 0] reg_down,
   input  [$clog2(NUM_REGISTER) - 1 : 0]   access_addr,
   input                                    write_valid,
    
   output  logic                          read_start,
   output  logic                          read_restart,
   output  logic                          top_read_valid,
   output  logic  [TOP_LEN_WIDTH - 1 : 0] top_read_len,
   output  logic  [AXI_ADDR_WIDTH-1:0]    top_read_addr,

   output  logic                          write_start,
   output  logic                          write_restart,
   output  logic                          top_write_valid,
   output  logic  [TOP_LEN_WIDTH - 1 : 0] top_write_len,
   output  logic  [AXI_ADDR_WIDTH-1:0]    top_write_addr
);

   logic  [AXIL_DATA_WIDTH - 1 : 0]  read_command, write_command, general_command;
      
   assign general_command = reg_down[(0+1)*AXIL_DATA_WIDTH-1 : 0*AXIL_DATA_WIDTH];
   assign read_command = reg_down[(1+1)*AXIL_DATA_WIDTH-1 : 1*AXIL_DATA_WIDTH];
   assign write_command = reg_down[(2+1)*AXIL_DATA_WIDTH-1 : 2*AXIL_DATA_WIDTH];

   assign top_read_valid  = write_valid == 1 && access_addr == 1;
   assign top_write_valid = write_valid == 1 && access_addr == 2;

   assign read_restart  = write_valid == 1 && access_addr == 0 && general_command == 1;
   assign write_restart = write_valid == 1 && access_addr == 0 && general_command == 1;

   assign read_start  = write_valid == 1 && access_addr == 0 && general_command == 2;
   assign write_start = write_valid == 1 && access_addr == 0 && general_command == 2;

   assign top_read_len = read_command [TOP_LEN_WIDTH - 1 : 0];
//   assign top_read_addr = read_command [AXIL_DATA_WIDTH - 1 : AXIL_DATA_WIDTH - AXI_ADDR_WIDTH];
   assign top_read_addr = read_command [32 + AXI_ADDR_WIDTH - 1 : 32];
   assign top_write_len = write_command [TOP_LEN_WIDTH - 1 : 0];
//   assign top_write_addr = write_command [AXIL_DATA_WIDTH - 1 : AXIL_DATA_WIDTH - AXI_ADDR_WIDTH];
   assign top_write_addr = write_command [32 + AXI_ADDR_WIDTH - 1 : 32];
endmodule
