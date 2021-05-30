module sl11_cell #(
   parameter UP_PIPE = 1,
   parameter DOWN_PIPE = 1
)
(  
   input   SL_REQ     req_up,
   output  SL_RES     res_up,
   
   output   SL_REQ     req_down,
   input    SL_RES     res_down,
   
   input                clk,
   input                rst_n
);


   pipe_reg #(
      .WIDTH($bits(SL_RES),
      .STAGE(UP_PIPE)
   ) pipe_up 
   (
      .in(res_down),
      .out(res_up),
      .*
   );


   pipe_reg #(
      .WIDTH($bits(SL_REQ),
      .STAGE(DOWN_PIPE)
   ) pipe_down1
   (
      .in(req_up),
      .out(req_down),
      .*
   );

endmodule

