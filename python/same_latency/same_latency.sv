module sl_interconnect_4 (
   input     SL_REQ   host_req,
   output    SL_RES   host_res,
   output    SL_REQ   slave_req_0,
   input     SL_RES   slave_res_0,
   output    SL_REQ   slave_req_1,
   input     SL_RES   slave_res_1,
   output    SL_REQ   slave_req_2,
   input     SL_RES   slave_res_2,
   output    SL_REQ   slave_req_3,
   input     SL_RES   slave_res_3,
   input   clk,
   input   rst_n
);

   SL_REQ   inter_req_0;
   SL_REQ   inter_req_1;
   SL_REQ   inter_req_2;
   SL_REQ   inter_req_3;


   SL_RES   inter_res_0;
   SL_RES   inter_res_1;
   SL_RES   inter_res_2;
   SL_RES   inter_res_3;


assign  host_res = inter_res_6;
assign  inter_req_6 = host_req;
assign  slave_req_0 = inter_req_0;
assign  inter_res_0 = slave_res_0;
assign  slave_req_1 = inter_req_1;
assign  inter_res_1 = slave_res_1;
assign  slave_req_2 = inter_req_2;
assign  inter_res_2 = slave_res_2;
assign  slave_req_3 = inter_req_3;
assign  inter_res_3 = slave_res_3;

   sl21_cell #(
      .INDI(12),
      .UP_PIPE(1),
      .DOWN_PIPE(2),
   )
   sl21_inter_4_inter_0(
      .req_up(req_inter_4),
      .res_up(res_inter_4),
      .req_down0(req_inter_0),
      .res_down0(res_inter_0),
      .req_down1(req_inter_1),
      .res_down1(res_inter_1),
      .*
   );

   sl21_cell #(
      .INDI(12),
      .UP_PIPE(1),
      .DOWN_PIPE(2),
   )
   sl21_inter_5_inter_2(
      .req_up(req_inter_5),
      .res_up(res_inter_5),
      .req_down0(req_inter_2),
      .res_down0(res_inter_2),
      .req_down1(req_inter_3),
      .res_down1(res_inter_3),
      .*
   );



   sl21_cell #(
      .INDI(13),
      .UP_PIPE(1),
      .DOWN_PIPE(2),
   )
   sl21_inter_6_inter_4(
      .req_up(req_inter_6),
      .res_up(res_inter_6),
      .req_down0(req_inter_4),
      .res_down0(res_inter_4),
      .req_down1(req_inter_5),
      .res_down1(res_inter_5),
      .*
   );



endmodule
