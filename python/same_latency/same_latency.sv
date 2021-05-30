   sl21_cell #(
      .INDI(5),
      .UP_PIPE(1),
      .DOWN_PIPE(2),
   )
   sl21_sys_2_cis_4(
      .req_up(req_sys_2),
      .res_up(res_sys_2),
      .req_down0(req_cis_4),
      .res_down0(res_cis_4),
      .req_down1(req_cis_5),
      .res_down1(res_cis_5),
      .*
   );

   sl21_cell #(
      .INDI(5),
      .UP_PIPE(1),
      .DOWN_PIPE(2),
   )
   sl21_sys_3_cis_6(
      .req_up(req_sys_3),
      .res_up(res_sys_3),
      .req_down0(req_cis_6),
      .res_down0(res_cis_6),
      .req_down1(req_cis_7),
      .res_down1(res_cis_7),
      .*
   );

   sl21_cell #(
      .INDI(5),
      .UP_PIPE(1),
      .DOWN_PIPE(2),
   )
   sl21_sys_4_cis_8(
      .req_up(req_sys_4),
      .res_up(res_sys_4),
      .req_down0(req_cis_8),
      .res_down0(res_cis_8),
      .req_down1(req_cis_9),
      .res_down1(res_cis_9),
      .*
   );

   sl21_cell #(
      .INDI(5),
      .UP_PIPE(1),
      .DOWN_PIPE(2),
   )
   sl21_sys_5_cis_10(
      .req_up(req_sys_5),
      .res_up(res_sys_5),
      .req_down0(req_cis_10),
      .res_down0(res_cis_10),
      .req_down1(req_cis_11),
      .res_down1(res_cis_11),
      .*
   );

   sl21_cell #(
      .INDI(5),
      .UP_PIPE(1),
      .DOWN_PIPE(2),
   )
   sl21_sys_6_cis_12(
      .req_up(req_sys_6),
      .res_up(res_sys_6),
      .req_down0(req_cis_12),
      .res_down0(res_cis_12),
      .req_down1(req_cis_13),
      .res_down1(res_cis_13),
      .*
   );



