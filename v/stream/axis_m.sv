module axis_m # (
   parameter    WIDTH  = 32,
   parameter    MAX_LEN = 128
)
(
   output   logic  [WIDTH - 1 : 0]  m_axis_tdata,
   output   logic                   m_axis_tvalid,
   input                            m_axis_tready,
   output   logic                   m_axis_tlast,

   input                            clk,
   input                            rst_n,

   output   logic                   ready,
   input                            valid_in,
   input           [WIDTH - 1 : 0]  data_in,

   input                            config_valid,
   input  [$clog2(MAX_LEN) - 1 : 0] config_len
);

   logic   [WIDTH - 1 : 0]  wdata, rdata;
   logic                    push, pop, full, empty, valid;
   logic                    al_full, al_empty, ack, flush;

   assign flush = 0;         
  
   logic state, state_w;
   localparam  IDLE, RUN;
   logic [$clog2(MAX_LEN) - 1 : 0] count, count_w;
   logic [$clog2(MAX_LEN) - 1 : 0] len_store_w, len_store;
   
   assign ready = ~full;
   assign m_axis_tdata = rdata;
   assign m_axis_tvalid = valid && state == RUN;
   assign pop   = m_axis_tready && state == RUN;
   assign push = valid_in;
   assign wdata = data_in; 
   assign m_axis_tlast = state == RUN && count == len_store;

   d0fifo #(
      .WIDTH(WIDTH),
      .SIZE(4),
      .FULL(1),
      .EMPTY(1),
      .AL_FULL(0),
      .AL_EMPTY(0),
      .ACK(0),
      .VALID(1),
      .PEEK(1),
      .FLUSH(0)
   )d1(.*);


   always_comb begin
      len_store_w = len_store;
      count_w = count;
      state = state_w;
      if (state == IDLE) begin
         if (config_valid == 1) begin
            len_store_w = config_len;
            state_w = RUN;
         end
      end
      else begin
         if (m_axis_tready == 1 && m_axis_tvalid == 1) begin
            if (m_axis_tlast == 1) begin
               count_w = 1;
               state_w = IDLE; 
            end
            else begin
               count_w = count + 1;
            end
         end
      end
   end
 
   always_ff @ (posedge clk or negedge rst_n) begin
      if (rst_n == 0) begin
         state <= IDLE;
         count <= 1;
         len_store <= 0;
      end
      else begin
         state <= state_w;
         count <= count_w;
         len_store <= len_store_w;
      end
   end  
 

endmodule
