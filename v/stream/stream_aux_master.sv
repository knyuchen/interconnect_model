module stream_aux_master #(
   parameter DATA_WIDTH = 32
)
(
    input               clk,
    input               rst_n,
    output logic [DATA_WIDTH - 1 : 0]       tdata,
    output logic        tvalid,
    input               enable,
    input  [DATA_WIDTH - 1 : 0]       total_num,
    output logic        tlast,
    input               tready
);

    logic [DATA_WIDTH - 1 : 0]  count, count_w;

    assign tvalid = enable;

    assign tlast = count == total_num;
  
    assign count_w = (tvalid && tready) ? count + 1 : count;

    assign tdata = count;

    always_ff @ (posedge clk or negedge rst_n) begin
       if (rst_n == 0) begin
          count <= 1;
       end
       else begin
          count <= count_w;
       end
    end



endmodule
