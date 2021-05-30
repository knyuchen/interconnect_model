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

   sl11_cell #(
      .UP_PIPE(1),
      .DOWN_PIPE(2),
   )
   sl11_sys_3_cis_5(
      .req_up(req_sys_3),
      .res_up(res_sys_3),
      .req_down(req_cis_5),
      .res_down(res_cis_5),
      .*
   );

