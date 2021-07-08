// Making Syntax more compatible with SystemVerilog & ASIC tools 


/*
 * AXI4 RAM
 */
module axi_ram #
(
    // Width of data bus in bits
    parameter DATA_WIDTH = 32,
    // Width of address bus in bits
    parameter ADDR_WIDTH = 32,
    parameter EFF_ADDR_WIDTH = 6,
    // Width of wstrb (width of data bus in words)
    parameter STRB_WIDTH = (DATA_WIDTH/8),
    // Width of ID signal
    parameter ID_WIDTH = 8,
    // Extra pipeline register on output
    parameter PIPELINE_OUTPUT = 0
)
(
    input                          clk,
    input                          rst,

    input        [ID_WIDTH-1:0]    s_axi_awid,
    input        [ADDR_WIDTH-1:0]  s_axi_awaddr,
    input        [7:0]             s_axi_awlen,
    input        [2:0]             s_axi_awsize,
    input        [1:0]             s_axi_awburst,
    input                          s_axi_awlock,
    input        [3:0]             s_axi_awcache,
    input        [2:0]             s_axi_awprot,
    input                          s_axi_awvalid,
    output logic                   s_axi_awready,
    input        [DATA_WIDTH-1:0]  s_axi_wdata,
    input        [STRB_WIDTH-1:0]  s_axi_wstrb,
    input                          s_axi_wlast,
    input                          s_axi_wvalid,
    output logic                   s_axi_wready,
    output logic [ID_WIDTH-1:0]    s_axi_bid,
    output logic [1:0]             s_axi_bresp,
    output logic                   s_axi_bvalid,
    input                          s_axi_bready,
    input        [ID_WIDTH-1:0]    s_axi_arid,
    input        [ADDR_WIDTH-1:0]  s_axi_araddr,
    input        [7:0]             s_axi_arlen,
    input        [2:0]             s_axi_arsize,
    input        [1:0]             s_axi_arburst,
    input                          s_axi_arlock,
    input        [3:0]             s_axi_arcache,
    input        [2:0]             s_axi_arprot,
    input                          s_axi_arvalid,
    output logic                   s_axi_arready,
    output logic [ID_WIDTH-1:0]    s_axi_rid,
    output logic [DATA_WIDTH-1:0]  s_axi_rdata,
    output logic [1:0]             s_axi_rresp,
    output logic                   s_axi_rlast,
    output logic                   s_axi_rvalid,
    input                          s_axi_rready
);

localparam VALID_ADDR_WIDTH = ADDR_WIDTH - $clog2(STRB_WIDTH);
localparam WORD_WIDTH = STRB_WIDTH;
localparam WORD_SIZE = DATA_WIDTH/WORD_WIDTH;


localparam [0:0]
    READ_STATE_IDLE = 1'd0,
    READ_STATE_BURST = 1'd1;

logic [0:0] read_state_flop, read_state_next;

localparam [1:0]
    WRITE_STATE_IDLE = 2'd0,
    WRITE_STATE_BURST = 2'd1,
    WRITE_STATE_RESP = 2'd2;

logic [1:0] write_state_flop, write_state_next;

logic mem_wr_en;
logic mem_rd_en;

logic [ID_WIDTH-1:0] read_id_flop, read_id_next;
logic [ADDR_WIDTH-1:0] read_addr_flop , read_addr_next;
logic [7:0] read_count_flop , read_count_next;
logic [2:0] read_size_flop , read_size_next;
logic [1:0] read_burst_flop , read_burst_next;
logic [ID_WIDTH-1:0] write_id_flop , write_id_next;
logic [ADDR_WIDTH-1:0] write_addr_flop , write_addr_next;
logic [7:0] write_count_flop , write_count_next;
logic [2:0] write_size_flop , write_size_next;
logic [1:0] write_burst_flop , write_burst_next;

logic s_axi_awready_flop , s_axi_awready_next;
logic s_axi_wready_flop , s_axi_wready_next;
logic [ID_WIDTH-1:0] s_axi_bid_flop , s_axi_bid_next;
logic s_axi_bvalid_flop , s_axi_bvalid_next;
logic s_axi_arready_flop , s_axi_arready_next;
logic [ID_WIDTH-1:0] s_axi_rid_flop , s_axi_rid_next;
logic [DATA_WIDTH-1:0] s_axi_rdata_flop , s_axi_rdata_next;
logic s_axi_rlast_flop , s_axi_rlast_next;
logic s_axi_rvalid_flop , s_axi_rvalid_next;
logic [ID_WIDTH-1:0] s_axi_rid_pipe_flop, s_axi_rid_pipe_flop_next ;
logic [DATA_WIDTH-1:0] s_axi_rdata_pipe_flop, s_axi_rdata_pipe_flop_next ;
logic s_axi_rlast_pipe_flop, s_axi_rlast_pipe_flop_next ;
logic s_axi_rvalid_pipe_flop, s_axi_rvalid_pipe_flop_next ;

// (* RAM_STYLE="BLOCK" *)
//logic [DATA_WIDTH-1:0] mem[(2**VALID_ADDR_WIDTH)-1:0];
//logic [(2**VALID_ADDR_WIDTH)-1:0][DATA_WIDTH-1:0] mem, mem_w;
//logic [(2**EFF_ADDR_WIDTH)-1:0][DATA_WIDTH-1:0] mem, mem_w;
logic [DATA_WIDTH-1:0]mem[0:2**EFF_ADDR_WIDTH-1];
logic [DATA_WIDTH-1:0]mem_w[0:2**EFF_ADDR_WIDTH-1];
//logic [(2**EFF_ADDR_WIDTH)-1:0]mem_w[DATA_WIDTH-1:0];

logic [VALID_ADDR_WIDTH-1:0] s_axi_awaddr_valid;
assign   s_axi_awaddr_valid = s_axi_awaddr >> (ADDR_WIDTH - VALID_ADDR_WIDTH);
logic [VALID_ADDR_WIDTH-1:0] s_axi_araddr_valid;
assign   s_axi_araddr_valid = s_axi_araddr >> (ADDR_WIDTH - VALID_ADDR_WIDTH);
logic [VALID_ADDR_WIDTH-1:0] read_addr_valid;
assign  read_addr_valid = read_addr_flop >> (ADDR_WIDTH - VALID_ADDR_WIDTH);
logic [VALID_ADDR_WIDTH-1:0] write_addr_valid;
assign  write_addr_valid = write_addr_flop >> (ADDR_WIDTH - VALID_ADDR_WIDTH);

assign s_axi_awready = s_axi_awready_flop;
assign s_axi_wready = s_axi_wready_flop;
assign s_axi_bid = s_axi_bid_flop;
assign s_axi_bresp = 2'b00;
assign s_axi_bvalid = s_axi_bvalid_flop;
assign s_axi_arready = s_axi_arready_flop;
assign s_axi_rid = PIPELINE_OUTPUT ? s_axi_rid_pipe_flop : s_axi_rid_flop;
assign s_axi_rdata = PIPELINE_OUTPUT ? s_axi_rdata_pipe_flop : s_axi_rdata_flop;
assign s_axi_rresp = 2'b00;
assign s_axi_rlast = PIPELINE_OUTPUT ? s_axi_rlast_pipe_flop : s_axi_rlast_flop;
assign s_axi_rvalid = PIPELINE_OUTPUT ? s_axi_rvalid_pipe_flop : s_axi_rvalid_flop;

integer i, j;
/*
initial begin
   $readmemb("/afs/eecs.umich.edu/vlsida/user/knyuchen/interconnect_model/python/random_number_gen/random.bin", mem);
end
*/
/*
initial begin
    // two nested loops for smaller number of iterations per loop
    // workaround for synthesizer complaints about large loop counts
    for (i = 0; i < 2**VALID_ADDR_WIDTH; i = i + 2**(VALID_ADDR_WIDTH/2)) begin
        for (j = i; j < i + 2**(VALID_ADDR_WIDTH/2); j = j + 1) begin
            mem[j] = 0;
        end
    end
end
*/
//always @* begin
always_comb begin
    write_state_next = WRITE_STATE_IDLE;

    mem_wr_en = 1'b0;

    write_id_next = write_id_flop;
    write_addr_next = write_addr_flop;
    write_count_next = write_count_flop;
    write_size_next = write_size_flop;
    write_burst_next = write_burst_flop;

    s_axi_awready_next = 1'b0;
    s_axi_wready_next = 1'b0;
    s_axi_bid_next = s_axi_bid_flop;
    s_axi_bvalid_next = s_axi_bvalid_flop && !s_axi_bready;

    case (write_state_flop)
        WRITE_STATE_IDLE: begin
            s_axi_awready_next = 1'b1;

            if (s_axi_awready && s_axi_awvalid) begin
                write_id_next = s_axi_awid;
                write_addr_next = s_axi_awaddr;
                write_count_next = s_axi_awlen;
                write_size_next = s_axi_awsize < $clog2(STRB_WIDTH) ? s_axi_awsize : $clog2(STRB_WIDTH);
                write_burst_next = s_axi_awburst;

                s_axi_awready_next = 1'b0;
                s_axi_wready_next = 1'b1;
                write_state_next = WRITE_STATE_BURST;
            end else begin
                write_state_next = WRITE_STATE_IDLE;
            end
        end
        WRITE_STATE_BURST: begin
            s_axi_wready_next = 1'b1;

            if (s_axi_wready && s_axi_wvalid) begin
                mem_wr_en = 1'b1;
                if (write_burst_flop != 2'b00) begin
                    write_addr_next = write_addr_flop + (1 << write_size_flop);
                end
                write_count_next = write_count_flop - 1;
                if (write_count_flop > 0) begin
                    write_state_next = WRITE_STATE_BURST;
                end else begin
                    s_axi_wready_next = 1'b0;
                    if (s_axi_bready || !s_axi_bvalid) begin
                        s_axi_bid_next = write_id_flop;
                        s_axi_bvalid_next = 1'b1;
                        s_axi_awready_next = 1'b1;
                        write_state_next = WRITE_STATE_IDLE;
                    end else begin
                        write_state_next = WRITE_STATE_RESP;
                    end
                end
            end else begin
                write_state_next = WRITE_STATE_BURST;
            end
        end
        WRITE_STATE_RESP: begin
            if (s_axi_bready || !s_axi_bvalid) begin
                s_axi_bid_next = write_id_flop;
                s_axi_bvalid_next = 1'b1;
                s_axi_awready_next = 1'b1;
                write_state_next = WRITE_STATE_IDLE;
            end else begin
                write_state_next = WRITE_STATE_RESP;
            end
        end
    endcase
end
/*
   patch start
*/    

  always_comb begin
    mem_w = mem;
    for (i = 0; i < WORD_WIDTH; i = i + 1) begin
        if (mem_wr_en & s_axi_wstrb[i]) begin
            mem_w[write_addr_valid[EFF_ADDR_WIDTH - 1 : 0]][WORD_SIZE*i +: WORD_SIZE] = s_axi_wdata[WORD_SIZE*i +: WORD_SIZE];
        end
    end
  end
/*
   patch end
*/    

always_ff @(posedge clk or posedge rst) begin
   if (rst == 1) begin
//   $readmemb("/afs/eecs.umich.edu/vlsida/users/knyuchen/interconnect_model/python/random_number_gen/random.bin", mem);
   $readmemb("/afs/eecs.umich.edu/vlsida/users/knyuchen/interconnect_model/python/ordered_number_gen/ordered.bin", mem);
   end
   else begin
    mem <= mem_w;
   end
end
always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        write_state_flop <= WRITE_STATE_IDLE;
    
    write_id_flop <= 0;
    write_addr_flop <= 0;
    write_count_flop <= 0;
    write_size_flop <= 0;
    write_burst_flop <= 0;

        s_axi_awready_flop <= 1'b0;
        s_axi_wready_flop <= 1'b0;
        s_axi_bid_flop <= 0;
        s_axi_bvalid_flop <= 1'b0;
    end
    else begin
    write_state_flop <= write_state_next;

    write_id_flop <= write_id_next;
    write_addr_flop <= write_addr_next;
    write_count_flop <= write_count_next;
    write_size_flop <= write_size_next;
    write_burst_flop <= write_burst_next;

    s_axi_awready_flop <= s_axi_awready_next;
    s_axi_wready_flop <= s_axi_wready_next;
    s_axi_bid_flop <= s_axi_bid_next;
    s_axi_bvalid_flop <= s_axi_bvalid_next;
    end
end

always_comb begin
    read_state_next = READ_STATE_IDLE;

    mem_rd_en = 1'b0;

    s_axi_rid_next = s_axi_rid_flop;
    s_axi_rlast_next = s_axi_rlast_flop;
    s_axi_rvalid_next = s_axi_rvalid_flop && !(s_axi_rready || (PIPELINE_OUTPUT && !s_axi_rvalid_pipe_flop));

    read_id_next = read_id_flop;
    read_addr_next = read_addr_flop;
    read_count_next = read_count_flop;
    read_size_next = read_size_flop;
    read_burst_next = read_burst_flop;

    s_axi_arready_next = 1'b0;

    case (read_state_flop)
        READ_STATE_IDLE: begin
            s_axi_arready_next = 1'b1;

            if (s_axi_arready && s_axi_arvalid) begin
                read_id_next = s_axi_arid;
                read_addr_next = s_axi_araddr;
                read_count_next = s_axi_arlen;
                read_size_next = s_axi_arsize < $clog2(STRB_WIDTH) ? s_axi_arsize : $clog2(STRB_WIDTH);
                read_burst_next = s_axi_arburst;

                s_axi_arready_next = 1'b0;
                read_state_next = READ_STATE_BURST;
            end else begin
                read_state_next = READ_STATE_IDLE;
            end
        end
        READ_STATE_BURST: begin
            if (s_axi_rready || (PIPELINE_OUTPUT && !s_axi_rvalid_pipe_flop) || !s_axi_rvalid_flop) begin
                mem_rd_en = 1'b1;
                s_axi_rvalid_next = 1'b1;
                s_axi_rid_next = read_id_flop;
                s_axi_rlast_next = read_count_flop == 0;
                if (read_burst_flop != 2'b00) begin
                    read_addr_next = read_addr_flop + (1 << read_size_flop);
                end
                read_count_next = read_count_flop - 1;
                if (read_count_flop > 0) begin
                    read_state_next = READ_STATE_BURST;
                end else begin
                    s_axi_arready_next = 1'b1;
                    read_state_next = READ_STATE_IDLE;
                end
            end else begin
                read_state_next = READ_STATE_BURST;
            end
        end
    endcase
end
/*
    patch start
*/
assign s_axi_rdata_next = (mem_rd_en == 1) ? mem[read_addr_valid] : s_axi_rdata_flop;
assign s_axi_rid_pipe_flop_next    = (!s_axi_rvalid_pipe_flop || s_axi_rready) ? s_axi_rid_flop    : s_axi_rid_pipe_flop;
assign s_axi_rdata_pipe_flop_next  = (!s_axi_rvalid_pipe_flop || s_axi_rready) ? s_axi_rdata_flop  : s_axi_rdata_pipe_flop;
assign s_axi_rlast_pipe_flop_next  = (!s_axi_rvalid_pipe_flop || s_axi_rready) ? s_axi_rlast_flop  : s_axi_rlast_pipe_flop;
assign s_axi_rvalid_pipe_flop_next = (!s_axi_rvalid_pipe_flop || s_axi_rready) ? s_axi_rvalid_flop : s_axi_rvalid_pipe_flop;

/*
   patch end
*/


always @(posedge clk or posedge rst) begin

    if (rst) begin
        read_state_flop <= READ_STATE_IDLE;

    read_id_flop <= 0;
    read_addr_flop <= 0;
    read_count_flop <= 0;
    read_size_flop <= 0;
    read_burst_flop <= 0;
    
        s_axi_arready_flop <= 1'b0;
    s_axi_rid_flop <= 0;
    s_axi_rlast_flop <= 0;
        s_axi_rvalid_flop <= 1'b0;
        s_axi_rdata_flop <= 0;
        
        s_axi_rid_pipe_flop <= s_axi_rid_flop;
        s_axi_rdata_pipe_flop <= s_axi_rdata_flop;
        s_axi_rlast_pipe_flop <= s_axi_rlast_flop;
      s_axi_rvalid_pipe_flop <= 1'b0;
    end
    else begin
    read_state_flop <= read_state_next;

    read_id_flop <= read_id_next;
    read_addr_flop <= read_addr_next;
    read_count_flop <= read_count_next;
    read_size_flop <= read_size_next;
    read_burst_flop <= read_burst_next;

    s_axi_arready_flop <= s_axi_arready_next;
    s_axi_rid_flop <= s_axi_rid_next;
    s_axi_rlast_flop <= s_axi_rlast_next;
    s_axi_rvalid_flop <= s_axi_rvalid_next;

/*    
    if (mem_rd_en) begin
        s_axi_rdata_flop <= mem[read_addr_valid];
    end
*/
        s_axi_rdata_flop <= s_axi_rdata_next;
/*
    if (!s_axi_rvalid_pipe_flop || s_axi_rready) begin
        s_axi_rid_pipe_flop <= s_axi_rid_flop;
        s_axi_rdata_pipe_flop <= s_axi_rdata_flop;
        s_axi_rlast_pipe_flop <= s_axi_rlast_flop;
        s_axi_rvalid_pipe_flop <= s_axi_rvalid_flop;
    end
*/
        s_axi_rid_pipe_flop <= s_axi_rid_pipe_flop_next;
        s_axi_rdata_pipe_flop <= s_axi_rdata_pipe_flop_next;
        s_axi_rlast_pipe_flop <= s_axi_rlast_pipe_flop_next;
        s_axi_rvalid_pipe_flop <= s_axi_rvalid_pipe_flop_next;
    end
end

endmodule
