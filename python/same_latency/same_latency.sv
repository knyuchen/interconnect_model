module sl_interconnect_16 (
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
   output    SL_REQ   slave_req_4,
   input     SL_RES   slave_res_4,
   output    SL_REQ   slave_req_5,
   input     SL_RES   slave_res_5,
   output    SL_REQ   slave_req_6,
   input     SL_RES   slave_res_6,
   output    SL_REQ   slave_req_7,
   input     SL_RES   slave_res_7,
   output    SL_REQ   slave_req_8,
   input     SL_RES   slave_res_8,
   output    SL_REQ   slave_req_9,
   input     SL_RES   slave_res_9,
   output    SL_REQ   slave_req_10,
   input     SL_RES   slave_res_10,
   output    SL_REQ   slave_req_11,
   input     SL_RES   slave_res_11,
   output    SL_REQ   slave_req_12,
   input     SL_RES   slave_res_12,
   output    SL_REQ   slave_req_13,
   input     SL_RES   slave_res_13,
   output    SL_REQ   slave_req_14,
   input     SL_RES   slave_res_14,
   output    SL_REQ   slave_req_15,
   input     SL_RES   slave_res_15,
   input   clk,
   input   rst_n
);

   SL_REQ   req_inter_0;
   SL_REQ   req_inter_1;
   SL_REQ   req_inter_2;
   SL_REQ   req_inter_3;
   SL_REQ   req_inter_4;
   SL_REQ   req_inter_5;
   SL_REQ   req_inter_6;
   SL_REQ   req_inter_7;
   SL_REQ   req_inter_8;
   SL_REQ   req_inter_9;
   SL_REQ   req_inter_10;
   SL_REQ   req_inter_11;
   SL_REQ   req_inter_12;
   SL_REQ   req_inter_13;
   SL_REQ   req_inter_14;
   SL_REQ   req_inter_15;
   SL_REQ   req_inter_16;
   SL_REQ   req_inter_17;
   SL_REQ   req_inter_18;
   SL_REQ   req_inter_19;
   SL_REQ   req_inter_20;
   SL_REQ   req_inter_21;
   SL_REQ   req_inter_22;
   SL_REQ   req_inter_23;
   SL_REQ   req_inter_24;
   SL_REQ   req_inter_25;
   SL_REQ   req_inter_26;
   SL_REQ   req_inter_27;
   SL_REQ   req_inter_28;
   SL_REQ   req_inter_29;
   SL_REQ   req_inter_30;


   SL_RES   res_inter_0;
   SL_RES   res_inter_1;
   SL_RES   res_inter_2;
   SL_RES   res_inter_3;
   SL_RES   res_inter_4;
   SL_RES   res_inter_5;
   SL_RES   res_inter_6;
   SL_RES   res_inter_7;
   SL_RES   res_inter_8;
   SL_RES   res_inter_9;
   SL_RES   res_inter_10;
   SL_RES   res_inter_11;
   SL_RES   res_inter_12;
   SL_RES   res_inter_13;
   SL_RES   res_inter_14;
   SL_RES   res_inter_15;
   SL_RES   res_inter_16;
   SL_RES   res_inter_17;
   SL_RES   res_inter_18;
   SL_RES   res_inter_19;
   SL_RES   res_inter_20;
   SL_RES   res_inter_21;
   SL_RES   res_inter_22;
   SL_RES   res_inter_23;
   SL_RES   res_inter_24;
   SL_RES   res_inter_25;
   SL_RES   res_inter_26;
   SL_RES   res_inter_27;
   SL_RES   res_inter_28;
   SL_RES   res_inter_29;
   SL_RES   res_inter_30;


assign  host_res = res_inter_30;
assign  inter_req_30 = host_req;
assign  slave_req_0 = req_inter_0;
assign   res_inter_0 = slave_res_0;
assign  slave_req_1 = req_inter_1;
assign   res_inter_1 = slave_res_1;
assign  slave_req_2 = req_inter_2;
assign   res_inter_2 = slave_res_2;
assign  slave_req_3 = req_inter_3;
assign   res_inter_3 = slave_res_3;
assign  slave_req_4 = req_inter_4;
assign   res_inter_4 = slave_res_4;
assign  slave_req_5 = req_inter_5;
assign   res_inter_5 = slave_res_5;
assign  slave_req_6 = req_inter_6;
assign   res_inter_6 = slave_res_6;
assign  slave_req_7 = req_inter_7;
assign   res_inter_7 = slave_res_7;
assign  slave_req_8 = req_inter_8;
assign   res_inter_8 = slave_res_8;
assign  slave_req_9 = req_inter_9;
assign   res_inter_9 = slave_res_9;
assign  slave_req_10 = req_inter_10;
assign   res_inter_10 = slave_res_10;
assign  slave_req_11 = req_inter_11;
assign   res_inter_11 = slave_res_11;
assign  slave_req_12 = req_inter_12;
assign   res_inter_12 = slave_res_12;
assign  slave_req_13 = req_inter_13;
assign   res_inter_13 = slave_res_13;
assign  slave_req_14 = req_inter_14;
assign   res_inter_14 = slave_res_14;
assign  slave_req_15 = req_inter_15;
assign   res_inter_15 = slave_res_15;

   sl21_cell #(
      .INDI(12),
      .UP_PIPE(2),
      .DOWN_PIPE(2)
   )
   sl21_inter_16_inter_0(
      .req_up(req_inter_16),
      .res_up(res_inter_16),
      .req_down0(req_inter_0),
      .res_down0(res_inter_0),
      .req_down1(req_inter_1),
      .res_down1(res_inter_1),
      .*
   );

   sl21_cell #(
      .INDI(12),
      .UP_PIPE(2),
      .DOWN_PIPE(2)
   )
   sl21_inter_17_inter_2(
      .req_up(req_inter_17),
      .res_up(res_inter_17),
      .req_down0(req_inter_2),
      .res_down0(res_inter_2),
      .req_down1(req_inter_3),
      .res_down1(res_inter_3),
      .*
   );

   sl21_cell #(
      .INDI(12),
      .UP_PIPE(2),
      .DOWN_PIPE(2)
   )
   sl21_inter_18_inter_4(
      .req_up(req_inter_18),
      .res_up(res_inter_18),
      .req_down0(req_inter_4),
      .res_down0(res_inter_4),
      .req_down1(req_inter_5),
      .res_down1(res_inter_5),
      .*
   );

   sl21_cell #(
      .INDI(12),
      .UP_PIPE(2),
      .DOWN_PIPE(2)
   )
   sl21_inter_19_inter_6(
      .req_up(req_inter_19),
      .res_up(res_inter_19),
      .req_down0(req_inter_6),
      .res_down0(res_inter_6),
      .req_down1(req_inter_7),
      .res_down1(res_inter_7),
      .*
   );

   sl21_cell #(
      .INDI(12),
      .UP_PIPE(2),
      .DOWN_PIPE(2)
   )
   sl21_inter_20_inter_8(
      .req_up(req_inter_20),
      .res_up(res_inter_20),
      .req_down0(req_inter_8),
      .res_down0(res_inter_8),
      .req_down1(req_inter_9),
      .res_down1(res_inter_9),
      .*
   );

   sl21_cell #(
      .INDI(12),
      .UP_PIPE(2),
      .DOWN_PIPE(2)
   )
   sl21_inter_21_inter_10(
      .req_up(req_inter_21),
      .res_up(res_inter_21),
      .req_down0(req_inter_10),
      .res_down0(res_inter_10),
      .req_down1(req_inter_11),
      .res_down1(res_inter_11),
      .*
   );

   sl21_cell #(
      .INDI(12),
      .UP_PIPE(2),
      .DOWN_PIPE(2)
   )
   sl21_inter_22_inter_12(
      .req_up(req_inter_22),
      .res_up(res_inter_22),
      .req_down0(req_inter_12),
      .res_down0(res_inter_12),
      .req_down1(req_inter_13),
      .res_down1(res_inter_13),
      .*
   );

   sl21_cell #(
      .INDI(12),
      .UP_PIPE(2),
      .DOWN_PIPE(2)
   )
   sl21_inter_23_inter_14(
      .req_up(req_inter_23),
      .res_up(res_inter_23),
      .req_down0(req_inter_14),
      .res_down0(res_inter_14),
      .req_down1(req_inter_15),
      .res_down1(res_inter_15),
      .*
   );



   sl21_cell #(
      .INDI(13),
      .UP_PIPE(2),
      .DOWN_PIPE(2)
   )
   sl21_inter_24_inter_16(
      .req_up(req_inter_24),
      .res_up(res_inter_24),
      .req_down0(req_inter_16),
      .res_down0(res_inter_16),
      .req_down1(req_inter_17),
      .res_down1(res_inter_17),
      .*
   );

   sl21_cell #(
      .INDI(13),
      .UP_PIPE(2),
      .DOWN_PIPE(2)
   )
   sl21_inter_25_inter_18(
      .req_up(req_inter_25),
      .res_up(res_inter_25),
      .req_down0(req_inter_18),
      .res_down0(res_inter_18),
      .req_down1(req_inter_19),
      .res_down1(res_inter_19),
      .*
   );

   sl21_cell #(
      .INDI(13),
      .UP_PIPE(2),
      .DOWN_PIPE(2)
   )
   sl21_inter_26_inter_20(
      .req_up(req_inter_26),
      .res_up(res_inter_26),
      .req_down0(req_inter_20),
      .res_down0(res_inter_20),
      .req_down1(req_inter_21),
      .res_down1(res_inter_21),
      .*
   );

   sl21_cell #(
      .INDI(13),
      .UP_PIPE(2),
      .DOWN_PIPE(2)
   )
   sl21_inter_27_inter_22(
      .req_up(req_inter_27),
      .res_up(res_inter_27),
      .req_down0(req_inter_22),
      .res_down0(res_inter_22),
      .req_down1(req_inter_23),
      .res_down1(res_inter_23),
      .*
   );



   sl21_cell #(
      .INDI(14),
      .UP_PIPE(2),
      .DOWN_PIPE(2)
   )
   sl21_inter_28_inter_24(
      .req_up(req_inter_28),
      .res_up(res_inter_28),
      .req_down0(req_inter_24),
      .res_down0(res_inter_24),
      .req_down1(req_inter_25),
      .res_down1(res_inter_25),
      .*
   );

   sl21_cell #(
      .INDI(14),
      .UP_PIPE(2),
      .DOWN_PIPE(2)
   )
   sl21_inter_29_inter_26(
      .req_up(req_inter_29),
      .res_up(res_inter_29),
      .req_down0(req_inter_26),
      .res_down0(res_inter_26),
      .req_down1(req_inter_27),
      .res_down1(res_inter_27),
      .*
   );



   sl21_cell #(
      .INDI(15),
      .UP_PIPE(2),
      .DOWN_PIPE(2)
   )
   sl21_inter_30_inter_28(
      .req_up(req_inter_30),
      .res_up(res_inter_30),
      .req_down0(req_inter_28),
      .res_down0(res_inter_28),
      .req_down1(req_inter_29),
      .res_down1(res_inter_29),
      .*
   );



endmodule
