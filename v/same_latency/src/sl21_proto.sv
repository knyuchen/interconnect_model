module sl21_cell (
   // write request from top
   input                              wen,
   input        [ADDR_WIDTH - 1 : 0]  waddr,
   input        [DATA_WIDTH - 1 : 0]  wdata,
   input        [ID_WIDTH - 1 : 0]    wid
   
   input                              ren,
   input        [ADDR_WIDTH - 1 : 0]  raddr,
   input        [ID_WIDTH - 1 : 0]    rid,
   // response to top
   output logic                       rvalid,
   output logic [DATA_WIDTH - 1 : 0]  rdata,
   output logic [ID_WIDTH - 1 : 0]    id,
   // request to down 0
   output logic                       wen0,
   output logic  [ADDR_WIDTH - 1 : 0] waddr0,
   output logic  [DATA_WIDTH - 1 : 0] wdata0,
   output logic  [ID_WIDTH - 1 : 0]   wid0,
   
   output logic                       ren0,
   output logic  [ADDR_WIDTH - 1 : 0] raddr0,
   output logic  [ID_WIDTH - 1 : 0]   rid0,
   // response from down 0
   input                              rvalid0,
   input         [DATA_WIDTH - 1 : 0] rdata0,
   input         [ID_WIDTH - 1 : 0]   id0,
   // request to down 1
   output logic                       wen1,
   output logic  [ADDR_WIDTH - 1 : 0] waddr1,
   output logic  [DATA_WIDTH - 1 : 0] wdata1,
   output logic  [ID_WIDTH - 1 : 0]   wid1,
   
   output logic                       ren1,
   output logic  [ADDR_WIDTH - 1 : 0] raddr1,
   output logic  [ID_WIDTH - 1 : 0]   rid1,
   // response from down 1 
   input                              rvalid1,
   input         [DATA_WIDTH - 1 : 0] rdata1,
   input         [ID_WIDTH - 1 : 0]   id1,

   input                              clk,
   input                              rst_n

);


endmodule
