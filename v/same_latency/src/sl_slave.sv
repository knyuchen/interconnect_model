module sl_slave #(
   parameter  WIDTH = 32,
   parameter  SIZE  = 64
)
(  
   input            clk,
   input            rst_n,
   input   SL_REQ   req,
   output  SL_RES   res
);

   logic [WIDTH - 1 : 0]mem  [0 : SIZE - 1];
   logic [WIDTH - 1 : 0]mem_w[0 : SIZE - 1];

   logic [$clog2(SIZE) - 1 : 0]  waddr, raddr;

   assign waddr = req.wreq.waddr[$clog2(SIZE) - 1 : 0];
   assign raddr = req.rreq.raddr[$clog2(SIZE) - 1 : 0];

   SL_RES res_w;

`ifdef SL_MULTI_MASTER
   assign res_w.rid = req.rreq.rid;
`endif 

   assign res_w.rdata = (req.rreq.ren == 1) ? mem[raddr] : 0;
   assign res_w.rvalid = req.rreq.ren;

   always_comb begin
      mem_w = mem;
      if (req.wreq.wen == 1) mem_w[waddr] = req.wreq.wdata;
   end


   always_ff @ (posedge clk or negedge rst_n) begin
      if (rst_n == 0) begin
         res <= 0;
         $readmemb("/afs/eecs.umich.edu/vlsida/users/knyuchen/interconnect_model/python/ordered_number_gen/ordered.bin", mem);
      end
      else begin
         res <= res_w;
         mem <= mem_w;
      end
   end


endmodule
