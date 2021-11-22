/*
   Revisions:
      10/08/21: First Documentation
*/
module axis_s # (
   parameter    WIDTH  = 32
)
(
/*
   Input from previous stage, axis slave interface
*/
   input           [WIDTH-1:0]      s_axis_tdata,
   input                            s_axis_tvalid,
   output   logic                   s_axis_tready,
   input                            s_axis_tlast,

   input                            clk,
   input                            rst_n,
/*
   Output to next stage, gives last_out information as well, same cycle of ready / valid
   No Peeking, valid is triggered by ready
*/
   input                            ready,
   output   logic                   valid_out,
   output   logic  [WIDTH - 1 : 0]  data_out,
   output   logic                   last_out
);

   logic   [WIDTH : 0]  wdata, rdata;
   logic                    push, pop, full, empty, valid;
   logic                    al_full, al_empty, ack, flush;

   assign flush = 0;         

   assign wdata         = {s_axis_tlast, s_axis_tdata};
   assign valid_out     = valid;
   assign data_out      = rdata[WIDTH - 1 : 0];
   assign last_out      = rdata[WIDTH];
   assign pop           = ready;
   assign s_axis_tready = ~full || pop == 1;
   assign push          = s_axis_tvalid; 


   d0fifo #(
      .WIDTH(WIDTH+1),
      .SIZE(4),
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
