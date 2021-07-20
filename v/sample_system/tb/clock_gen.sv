`define CLK_CYCLE      1.31
`define SETUP_CYCLE    0.5
`define RESET_CYCLE    12.3

program automatic  clk_gen # 
(
   CLK_CYCLE   = `CLK_CYCLE,
   RESET_CYCLE = `RESET_CYCLE
)
(
   output   logic   clk,
   output   logic   rst_n
);

   initial begin
      clk = 0;
      forever begin
         # (CLK_CYCLE / 2.0)
         clk = ~clk; 
      end
   end

   initial begin
      rst_n = 1;
      # (CLK_CYCLE * (($random % 10) / 5.0))
      rst_n = 0;
      # (CLK_CYCLE * RESET_CYCLE)
      rst_n = 1;
   end


endprogram

   logic dummy;
   
   task delay_cycle ();
  
      input real number;
      begin
         #(number * `CLK_CYCLE)
         $display("delay %g cycles", number);
      //   dummy = 1;
      end
   endtask

