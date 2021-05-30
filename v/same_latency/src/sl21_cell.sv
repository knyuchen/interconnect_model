module sl21_cell #(
   parameter INDI = 13,
   parameter UP_PIPE = 1,
   parameter DOWN_PIPE = 1
)
(  
   input   SL_REQ     req_up,
   output  SL_RES     res_up,
   
   output   SL_REQ     req_down0,
   input    SL_RES     res_down0,
   
   output   SL_REQ     req_down1,
   input    SL_RES     res_down1,

   input                clk,
   input                rst_n
);

   SL_RES   res_up_pre;

   pipe_reg #(
      .WIDTH($bits(SL_RES),
      .STAGE(UP_PIPE)
   ) pipe_up 
   (
      .in(res_up_pre),
      .out(res_up),
      .*
   );
   always_comb begin
      res_up_pre = 0;
      if (res_down0.rvalid == 1) res_up_pre = res_down0;
      else if (res_down1.rvalid == 1) res_up_pre = res_down1;
   end


   SL_WREQ  wreq_down0_pre, wreq_down1_pre;
   SL_RREQ  rreq_down0_pre, rreq_down1_pre;

   SL_REQ   req_down0_pre, req_down1_pre;

   pipe_reg #(
      .WIDTH($bits(SL_REQ),
      .STAGE(DOWN_PIPE)
   ) pipe_down0
   (
      .in(req_down0_pre),
      .out(req_down0),
      .*
   );
   pipe_reg #(
      .WIDTH($bits(SL_REQ),
      .STAGE(DOWN_PIPE)
   ) pipe_down1
   (
      .in(req_down1_pre),
      .out(req_down1),
      .*
   );
   assign req_down0_pre.req = rreq_down0_pre;
   assign req_down0_pre.weq = wreq_down0_pre;
   assign req_down1_pre.req = rreq_down1_pre;
   assign req_down1_pre.weq = wreq_down1_pre;

   always_comb begin
      wreq_down0_pre = 0;
      wreq_down1_pre = 0;
      if (req_up.wreq.wen == 1) begin
         if (req_up.wreq.waddr[INDI] == 0) wreq_down0_pre = req_up.wreq; 
         else if (req_up.wreq.waddr[INDI] == 1) wreq_down1_pre = req_up.wreq; 
      end
   end
   always_comb begin
      rreq_down0_pre = 0;
      rreq_down1_pre = 0;
      if (req_up.rreq.ren == 1) begin
         if (req_up.rreq.raddr[INDI] == 0) rreq_down0_pre = req_up.rreq; 
         else if (req_up.rreq.raddr[INDI] == 1) rreq_down1_pre = req_up.rreq; 
      end
   end

endmodule

