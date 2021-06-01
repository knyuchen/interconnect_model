   sl21_cell #(
      .INDI(5),
      .UP_PIPE(1),
      .DOWN_PIPE(2),
   )
   sl21_sys_10_sys_0(
      .req_up(req_sys_10),
      .res_up(res_sys_10),
      .req_down0(req_sys_0),
      .res_down0(res_sys_0),
      .req_down1(req_sys_1),
      .res_down1(res_sys_1),
      .*
   );

   sl21_cell #(
      .INDI(5),
      .UP_PIPE(1),
      .DOWN_PIPE(2),
   )
   sl21_sys_11_sys_2(
      .req_up(req_sys_11),
      .res_up(res_sys_11),
      .req_down0(req_sys_2),
      .res_down0(res_sys_2),
      .req_down1(req_sys_3),
      .res_down1(res_sys_3),
      .*
   );

   sl21_cell #(
      .INDI(5),
      .UP_PIPE(1),
      .DOWN_PIPE(2),
   )
   sl21_sys_12_sys_4(
      .req_up(req_sys_12),
      .res_up(res_sys_12),
      .req_down0(req_sys_4),
      .res_down0(res_sys_4),
      .req_down1(req_sys_5),
      .res_down1(res_sys_5),
      .*
   );

   sl21_cell #(
      .INDI(5),
      .UP_PIPE(1),
      .DOWN_PIPE(2),
   )
   sl21_sys_13_sys_6(
      .req_up(req_sys_13),
      .res_up(res_sys_13),
      .req_down0(req_sys_6),
      .res_down0(res_sys_6),
      .req_down1(req_sys_7),
      .res_down1(res_sys_7),
      .*
   );

   sl21_cell #(
      .INDI(5),
      .UP_PIPE(1),
      .DOWN_PIPE(2),
   )
   sl21_sys_14_sys_8(
      .req_up(req_sys_14),
      .res_up(res_sys_14),
      .req_down0(req_sys_8),
      .res_down0(res_sys_8),
      .req_down1(req_sys_9),
      .res_down1(res_sys_9),
      .*
   );



   sl21_cell #(
      .INDI(6),
      .UP_PIPE(1),
      .DOWN_PIPE(2),
   )
   sl21_sys_15_sys_10(
      .req_up(req_sys_15),
      .res_up(res_sys_15),
      .req_down0(req_sys_10),
      .res_down0(res_sys_10),
      .req_down1(req_sys_11),
      .res_down1(res_sys_11),
      .*
   );

   sl21_cell #(
      .INDI(6),
      .UP_PIPE(1),
      .DOWN_PIPE(2),
   )
   sl21_sys_16_sys_12(
      .req_up(req_sys_16),
      .res_up(res_sys_16),
      .req_down0(req_sys_12),
      .res_down0(res_sys_12),
      .req_down1(req_sys_13),
      .res_down1(res_sys_13),
      .*
   );

   sl11_cell #(
      .UP_PIPE(1),
      .DOWN_PIPE(2),
   )
   sl11_sys_17_sys_14(
      .req_up(req_sys_17),
      .res_up(res_sys_17),
      .req_down(req_sys_14),
      .res_down(res_sys_14),
      .*
   );



   sl21_cell #(
      .INDI(7),
      .UP_PIPE(2),
      .DOWN_PIPE(1),
   )
   sl21_sys_18_sys_15(
      .req_up(req_sys_18),
      .res_up(res_sys_18),
      .req_down0(req_sys_15),
      .res_down0(res_sys_15),
      .req_down1(req_sys_16),
      .res_down1(res_sys_16),
      .*
   );

   sl11_cell #(
      .UP_PIPE(2),
      .DOWN_PIPE(1),
   )
   sl11_sys_19_sys_17(
      .req_up(req_sys_19),
      .res_up(res_sys_19),
      .req_down(req_sys_17),
      .res_down(res_sys_17),
      .*
   );



   sl21_cell #(
      .INDI(8),
      .UP_PIPE(2),
      .DOWN_PIPE(1),
   )
   sl21_sys_20_sys_18(
      .req_up(req_sys_20),
      .res_up(res_sys_20),
      .req_down0(req_sys_18),
      .res_down0(res_sys_18),
      .req_down1(req_sys_19),
      .res_down1(res_sys_19),
      .*
   );



