/*
  DMA controller that further dice up data commands
  user only inputs once per transaction
  pushes command into the buffer of the command dispatcher inside rd / wr
  Independent rd / wr operations

  Revisions:
     10/12/21:
        First Documentation, might want to look at different FIX_LEN in the future, don't change for now
*/
module dma_control #(
    parameter AXI_ADDR_WIDTH = 32,
    parameter AXI_DATA_WIDTH = 32,
    parameter TOP_LEN_WIDTH  = 32,
    parameter FIX_LEN        = 64,
    parameter RATE           = AXI_DATA_WIDTH / 8,
    parameter CONFIG_LEN_WIDTH = 9
)
(
/*
   to dma_rd
*/
    output   logic                         read_config_valid,
    input                                  read_config_ready,
    input                                  read_config_empty,
    output   logic [CONFIG_LEN_WIDTH-1:0]  read_config_len, 
    output   logic [AXI_ADDR_WIDTH-1:0]    read_config_addr, 
/*
   to dma_wr
*/    
    output   logic                         write_config_valid,
    input                                  write_config_ready,
    input                                  write_config_empty,
    output   logic [CONFIG_LEN_WIDTH-1:0]  write_config_len, 
    output   logic [AXI_ADDR_WIDTH-1:0]    write_config_addr, 
/*
   read instructions from user
*/
    // more like ready rather than done tbh
    output   logic                         read_done,
    input                                  read_start,
    input                                  top_read_valid,
    input          [TOP_LEN_WIDTH - 1 : 0] top_read_len,
    input          [AXI_ADDR_WIDTH-1:0]    top_read_addr,
/*
   write instructions from user
*/
    output   logic                         write_done,
    input                                  write_start,
    input                                  top_write_valid,
    input          [TOP_LEN_WIDTH - 1 : 0] top_write_len,
    input          [AXI_ADDR_WIDTH-1:0]    top_write_addr,

    input                                  clk,
    input                                  rst_n
);
/*
   Registers to latch up user commands
*/    
    logic  [AXI_ADDR_WIDTH-1 : 0] read_addr_store, read_addr_store_w; 
    logic  [AXI_ADDR_WIDTH-1 : 0] write_addr_store, write_addr_store_w; 
    
    logic  [TOP_LEN_WIDTH-1 : 0]  read_len_store, read_len_store_w;
    logic  [TOP_LEN_WIDTH-1 : 0]  write_len_store, write_len_store_w;

    logic                         read_done_w, write_done_w;

    /*
      handle read
    */
    always_comb begin
/*
   commands going to dma_rd
*/
       read_config_valid = 0;
       read_config_len = 0;
       read_config_addr = 0;
/*
   storing
*/
       read_addr_store_w = read_addr_store;
       read_len_store_w = read_len_store;
/*
   state machine
*/
       read_done_w = read_done;
       if (read_done == 1) begin
/*
   first load the instructions, just need to load once
*/
          if (top_read_valid == 1) begin
             read_addr_store_w = top_read_addr;
             read_len_store_w = top_read_len;
          end
/*
   wait for start
*/
          else if (read_start == 1) read_done_w = 0;
       end
       else begin
         // no more len to go on
          if (read_len_store == 0) begin
             // dma rd complete, dma empty is defined as fifo empty && in state WAIT COMMAND, guaranteed finish
             if (read_config_empty == 1) read_done_w = 1;
          end
          else begin
/*
   this valid / ready handshaking is "valid regardless" type
*/
             read_config_addr = read_addr_store;
             read_config_valid = 1;
/*
   dice up len
*/
             if (read_len_store < FIX_LEN) read_config_len = read_len_store;
             else read_config_len = FIX_LEN;
/*
   makes sure that dma_rd gets the command
   no way that dma_rd is empty falsely
*/
 
             if (read_config_ready == 1) begin
                read_addr_store_w = read_addr_store + FIX_LEN*RATE;
                if (read_len_store < FIX_LEN) read_len_store_w = 0;
                else read_len_store_w = read_len_store - FIX_LEN;
             end
          end
       end
    end
    /*
      handle write
    */
    always_comb begin
       write_config_valid = 0;
       write_config_len = 0;
       write_config_addr = 0;
       write_addr_store_w = write_addr_store;
       write_len_store_w = write_len_store;
       write_done_w = write_done;
       if (write_done == 1) begin
          if (top_write_valid == 1) begin
             write_addr_store_w = top_write_addr;
             write_len_store_w = top_write_len;
          end
          else if (write_start == 1) write_done_w = 0;
       end
       else begin
          if (write_len_store == 0) begin
             if (write_config_empty == 1) write_done_w = 1;
          end
          else begin
             write_config_addr = write_addr_store;
             write_config_valid = 1;
             if (write_len_store < FIX_LEN) write_config_len = write_len_store;
             else write_config_len = FIX_LEN;
             if (write_config_ready == 1) begin
                write_addr_store_w = write_addr_store + FIX_LEN*RATE;
                if (write_len_store < FIX_LEN) write_len_store_w = 0;
                else write_len_store_w = write_len_store - FIX_LEN;
             end
          end
       end
    end

    always_ff @ (posedge clk or negedge rst_n) begin
       if (rst_n == 0) begin
          read_done <= 1;
          read_len_store <= 0;
          read_addr_store <= 0;
          write_done <= 1;
          write_len_store <= 0;
          write_addr_store <= 0;
       end
       else begin
          read_done <= read_done_w;
          read_len_store <= read_len_store_w;
          read_addr_store <= read_addr_store_w;
          write_done <= write_done_w;
          write_len_store <= write_len_store_w;
          write_addr_store <= write_addr_store_w;
       end
    end

endmodule
