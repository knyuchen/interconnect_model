/*

Copyright (c) 2018 Alex Forencich

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

*/

// Language: Verilog 2001

//`timescale 1ns / 1ps

/*
 * AXI4 DMA
 */
module axi_dma_wr #
(
    // Width of AXI data bus in bits
    parameter AXI_DATA_WIDTH = 32,
    // Width of AXI address bus in bits
    parameter AXI_ADDR_WIDTH = 16,
    // Width of AXI wstrb (width of data bus in words)
    parameter AXI_STRB_WIDTH = (AXI_DATA_WIDTH/8),
    // Width of AXI ID signal
    parameter AXI_ID_WIDTH = 8,
    // Maximum AXI burst length to generate
    parameter AXI_MAX_BURST_LEN = 16,
    // Width of AXI stream interfaces in bits
    parameter AXIS_DATA_WIDTH = AXI_DATA_WIDTH,
    // Use AXI stream tkeep signal
    parameter AXIS_KEEP_ENABLE = (AXIS_DATA_WIDTH>8),
    // AXI stream tkeep signal width (words per cycle)
    parameter AXIS_KEEP_WIDTH = (AXIS_DATA_WIDTH/8),
    // Use AXI stream tlast signal
    parameter AXIS_LAST_ENABLE = 1,
    // Propagate AXI stream tid signal
    parameter AXIS_ID_ENABLE = 0,
    // AXI stream tid signal width
    parameter AXIS_ID_WIDTH = 8,
    // Propagate AXI stream tdest signal
    parameter AXIS_DEST_ENABLE = 0,
    // AXI stream tdest signal width
    parameter AXIS_DEST_WIDTH = 8,
    // Propagate AXI stream tuser signal
    parameter AXIS_USER_ENABLE = 1,
    // AXI stream tuser signal width
    parameter AXIS_USER_WIDTH = 1,
    // Width of length field
    parameter LEN_WIDTH = 20,
    // Width of tag field
    parameter TAG_WIDTH = 8,
    // Enable support for scatter/gather DMA
    // (multiple descriptors per AXI stream frame)
    parameter ENABLE_SG = 0,
    // Enable support for unaligned transfers
    parameter ENABLE_UNALIGNED = 0
)
(
    input                         clk,
    input                         rst,

    input          [AXI_ADDR_WIDTH-1:0]  s_axis_write_desc_addr,
    input          [LEN_WIDTH-1:0]       s_axis_write_desc_len,
    input          [TAG_WIDTH-1:0]       s_axis_write_desc_tag,
    input                                s_axis_write_desc_valid,
    output   logic                       s_axis_write_desc_ready,

    /*
     * AXI write descriptor status output
     */
    output   logic [LEN_WIDTH-1:0]       m_axis_write_desc_status_len,
    output   logic [TAG_WIDTH-1:0]       m_axis_write_desc_status_tag,
    output   logic [AXIS_ID_WIDTH-1:0]   m_axis_write_desc_status_id,
    output   logic [AXIS_DEST_WIDTH-1:0] m_axis_write_desc_status_dest,
    output   logic [AXIS_USER_WIDTH-1:0] m_axis_write_desc_status_user,
    output   logic                       m_axis_write_desc_status_valid,

    /*
     * AXI stream write data input
     */
    input          [AXIS_DATA_WIDTH-1:0] s_axis_write_data_tdata,
    input          [AXIS_KEEP_WIDTH-1:0] s_axis_write_data_tkeep,
    input                                s_axis_write_data_tvalid,
    output   logic                       s_axis_write_data_tready,
    input                                s_axis_write_data_tlast,
    input          [AXIS_ID_WIDTH-1:0]   s_axis_write_data_tid,
    input          [AXIS_DEST_WIDTH-1:0] s_axis_write_data_tdest,
    input          [AXIS_USER_WIDTH-1:0] s_axis_write_data_tuser,

    /*
     * AXI master interface
     */
    output   logic [AXI_ID_WIDTH-1:0]    m_axi_awid,
    output   logic [AXI_ADDR_WIDTH-1:0]  m_axi_awaddr,
    output   logic [7:0]                 m_axi_awlen,
    output   logic [2:0]                 m_axi_awsize,
    output   logic [1:0]                 m_axi_awburst,
    output   logic                       m_axi_awlock,
    output   logic [3:0]                 m_axi_awcache,
    output   logic [2:0]                 m_axi_awprot,
    output   logic                       m_axi_awvalid,
    input                                m_axi_awready,
    output   logic [AXI_DATA_WIDTH-1:0]  m_axi_wdata,
    output   logic [AXI_STRB_WIDTH-1:0]  m_axi_wstrb,
    output   logic                       m_axi_wlast,
    output   logic                       m_axi_wvalid,
    input                                m_axi_wready,
    input          [AXI_ID_WIDTH-1:0]    m_axi_bid,
    input          [1:0]                 m_axi_bresp,
    input                                m_axi_bvalid,
    output   logic                       m_axi_bready,

    /*
     * Configuration
     */
    input                                enable,
    input                                abort
);

localparam AXI_WORD_WIDTH = AXI_STRB_WIDTH;
localparam AXI_WORD_SIZE = AXI_DATA_WIDTH/AXI_WORD_WIDTH;
localparam AXI_BURST_SIZE = $clog2(AXI_STRB_WIDTH);
localparam AXI_MAX_BURST_SIZE = AXI_MAX_BURST_LEN << AXI_BURST_SIZE;

localparam AXIS_KEEP_WIDTH_INT = AXIS_KEEP_ENABLE ? AXIS_KEEP_WIDTH : 1;
localparam AXIS_WORD_WIDTH = AXIS_KEEP_WIDTH_INT;
localparam AXIS_WORD_SIZE = AXIS_DATA_WIDTH/AXIS_WORD_WIDTH;

localparam OFFSET_WIDTH = AXI_STRB_WIDTH > 1 ? $clog2(AXI_STRB_WIDTH) : 1;
localparam OFFSET_MASK = AXI_STRB_WIDTH > 1 ? {OFFSET_WIDTH{1'b1}} : 0;
localparam ADDR_MASK = {AXI_ADDR_WIDTH{1'b1}} << $clog2(AXI_STRB_WIDTH);
localparam CYCLE_COUNT_WIDTH = LEN_WIDTH - AXI_BURST_SIZE + 1;

localparam STATUS_FIFO_ADDR_WIDTH = 5;


localparam [2:0]
    STATE_IDLE = 3'd0,
    STATE_START = 3'd1,
    STATE_WRITE = 3'd2,
    STATE_FINISH_BURST = 3'd3,
    STATE_DROP_DATA = 3'd4;

logic [2:0] state_flop, state_next;

// datapath control signals
logic transfer_in_save;
logic flush_save;
logic status_fifo_we;

integer i;
logic [OFFSET_WIDTH:0] cycle_size;

logic [AXI_ADDR_WIDTH-1:0] addr_flop, addr_next;
logic [LEN_WIDTH-1:0] op_word_count_flop, op_word_count_next;
logic [LEN_WIDTH-1:0] tr_word_count_flop, tr_word_count_next;

logic [OFFSET_WIDTH-1:0] offset_flop, offset_next;
logic [AXI_STRB_WIDTH-1:0] strb_offset_mask_flop, strb_offset_mask_next;
logic zero_offset_flop, zero_offset_next;
logic [OFFSET_WIDTH-1:0] last_cycle_offset_flop, last_cycle_offset_next;
logic [LEN_WIDTH-1:0] length_flop, length_next;
logic [CYCLE_COUNT_WIDTH-1:0] input_cycle_count_flop, input_cycle_count_next;
logic [CYCLE_COUNT_WIDTH-1:0] output_cycle_count_flop, output_cycle_count_next;
logic input_active_flop, input_active_next;
logic first_cycle_flop, first_cycle_next;
logic input_last_cycle_flop, input_last_cycle_next;
logic output_last_cycle_flop, output_last_cycle_next;
logic last_transfer_flop, last_transfer_next;

logic [TAG_WIDTH-1:0] tag_flop, tag_next;
logic [AXIS_ID_WIDTH-1:0] axis_id_flop, axis_id_next;
logic [AXIS_DEST_WIDTH-1:0] axis_dest_flop, axis_dest_next;
logic [AXIS_USER_WIDTH-1:0] axis_user_flop, axis_user_next;

logic [STATUS_FIFO_ADDR_WIDTH+1-1:0] status_fifo_wr_ptr_flop, status_fifo_wr_ptr_flop_next;
logic [STATUS_FIFO_ADDR_WIDTH+1-1:0] status_fifo_rd_ptr_flop, status_fifo_rd_ptr_next;
/*
logic [LEN_WIDTH-1:0] status_fifo_len[(2**STATUS_FIFO_ADDR_WIDTH)-1:0];
logic [LEN_WIDTH-1:0] status_fifo_len_next[(2**STATUS_FIFO_ADDR_WIDTH)-1:0];
logic [TAG_WIDTH-1:0] status_fifo_tag[(2**STATUS_FIFO_ADDR_WIDTH)-1:0];
logic [TAG_WIDTH-1:0] status_fifo_tag_next[(2**STATUS_FIFO_ADDR_WIDTH)-1:0];
logic [AXIS_ID_WIDTH-1:0] status_fifo_id[(2**STATUS_FIFO_ADDR_WIDTH)-1:0];
logic [AXIS_ID_WIDTH-1:0] status_fifo_id_next[(2**STATUS_FIFO_ADDR_WIDTH)-1:0];
logic [AXIS_DEST_WIDTH-1:0] status_fifo_dest[(2**STATUS_FIFO_ADDR_WIDTH)-1:0];
logic [AXIS_DEST_WIDTH-1:0] status_fifo_dest_next[(2**STATUS_FIFO_ADDR_WIDTH)-1:0];
logic [AXIS_USER_WIDTH-1:0] status_fifo_user[(2**STATUS_FIFO_ADDR_WIDTH)-1:0];
logic [AXIS_USER_WIDTH-1:0] status_fifo_user_next[(2**STATUS_FIFO_ADDR_WIDTH)-1:0];
logic status_fifo_last[(2**STATUS_FIFO_ADDR_WIDTH)-1:0];
logic status_fifo_last_next[(2**STATUS_FIFO_ADDR_WIDTH)-1:0];
*/
logic [(2**STATUS_FIFO_ADDR_WIDTH)-1:0][LEN_WIDTH-1:0] status_fifo_len, status_fifo_len_next;
logic [(2**STATUS_FIFO_ADDR_WIDTH)-1:0][TAG_WIDTH-1:0] status_fifo_tag, status_fifo_tag_next;
logic [(2**STATUS_FIFO_ADDR_WIDTH)-1:0][AXIS_ID_WIDTH-1:0] status_fifo_id, status_fifo_id_next;
logic [(2**STATUS_FIFO_ADDR_WIDTH)-1:0][AXIS_DEST_WIDTH-1:0] status_fifo_dest, status_fifo_dest_next;
logic [(2**STATUS_FIFO_ADDR_WIDTH)-1:0][AXIS_USER_WIDTH-1:0] status_fifo_user, status_fifo_user_next;
logic [(2**STATUS_FIFO_ADDR_WIDTH)-1:0]status_fifo_last, status_fifo_last_next;



logic [LEN_WIDTH-1:0] status_fifo_wr_len;
logic [TAG_WIDTH-1:0] status_fifo_wr_tag;
logic [AXIS_ID_WIDTH-1:0] status_fifo_wr_id;
logic [AXIS_DEST_WIDTH-1:0] status_fifo_wr_dest;
logic [AXIS_USER_WIDTH-1:0] status_fifo_wr_user;
logic status_fifo_wr_last;

logic [STATUS_FIFO_ADDR_WIDTH+1-1:0] active_count_flop, active_count_flop_next;
logic active_count_av_flop, active_count_av_flop_next;
logic inc_active;
logic dec_active;

logic s_axis_write_desc_ready_flop, s_axis_write_desc_ready_next;

logic [LEN_WIDTH-1:0] m_axis_write_desc_status_len_flop, m_axis_write_desc_status_len_next;
logic [TAG_WIDTH-1:0] m_axis_write_desc_status_tag_flop, m_axis_write_desc_status_tag_next;
logic [AXIS_ID_WIDTH-1:0] m_axis_write_desc_status_id_flop, m_axis_write_desc_status_id_next;
logic [AXIS_DEST_WIDTH-1:0] m_axis_write_desc_status_dest_flop, m_axis_write_desc_status_dest_next;
logic [AXIS_USER_WIDTH-1:0] m_axis_write_desc_status_user_flop, m_axis_write_desc_status_user_next;
logic m_axis_write_desc_status_valid_flop, m_axis_write_desc_status_valid_next;

logic [AXI_ADDR_WIDTH-1:0] m_axi_awaddr_flop, m_axi_awaddr_next;
logic [7:0] m_axi_awlen_flop, m_axi_awlen_next;
logic m_axi_awvalid_flop, m_axi_awvalid_next;
logic m_axi_bready_flop, m_axi_bready_next;

logic s_axis_write_data_tready_flop, s_axis_write_data_tready_next;

logic [AXIS_DATA_WIDTH-1:0] save_axis_tdata_flop, save_axis_tdata_flop_next;
logic [AXIS_KEEP_WIDTH_INT-1:0] save_axis_tkeep_flop, save_axis_tkeep_flop_next;
logic save_axis_tlast_flop, save_axis_tlast_flop_next;

logic [AXIS_DATA_WIDTH-1:0] shift_axis_tdata;
logic [AXIS_KEEP_WIDTH_INT-1:0] shift_axis_tkeep;
logic shift_axis_tvalid;
logic shift_axis_tlast;
logic shift_axis_input_tready;
logic shift_axis_extra_cycle_flop, shift_axis_extra_cycle_flop_next;

// internal datapath
logic  [AXI_DATA_WIDTH-1:0] m_axi_wdata_int;
logic  [AXI_STRB_WIDTH-1:0] m_axi_wstrb_int;
logic                       m_axi_wlast_int;
logic                       m_axi_wvalid_int;
logic                       m_axi_wready_int_flop;
logic                      m_axi_wready_int_early;

assign s_axis_write_desc_ready = s_axis_write_desc_ready_flop;

assign m_axis_write_desc_status_len = m_axis_write_desc_status_len_flop;
assign m_axis_write_desc_status_tag = m_axis_write_desc_status_tag_flop;
assign m_axis_write_desc_status_id = m_axis_write_desc_status_id_flop;
assign m_axis_write_desc_status_dest = m_axis_write_desc_status_dest_flop;
assign m_axis_write_desc_status_user = m_axis_write_desc_status_user_flop;
assign m_axis_write_desc_status_valid = m_axis_write_desc_status_valid_flop;

assign s_axis_write_data_tready = s_axis_write_data_tready_flop;

assign m_axi_awid = {AXI_ID_WIDTH{1'b0}};
assign m_axi_awaddr = m_axi_awaddr_flop;
assign m_axi_awlen = m_axi_awlen_flop;
assign m_axi_awsize = AXI_BURST_SIZE;
assign m_axi_awburst = 2'b01;
assign m_axi_awlock = 1'b0;
assign m_axi_awcache = 4'b0011;
assign m_axi_awprot = 3'b010;
assign m_axi_awvalid = m_axi_awvalid_flop;
assign m_axi_bready = m_axi_bready_flop;

always_comb begin
    if (!ENABLE_UNALIGNED || zero_offset_flop) begin
        // passthrough if no overlap
        shift_axis_tdata = s_axis_write_data_tdata;
        shift_axis_tkeep = s_axis_write_data_tkeep;
        shift_axis_tvalid = s_axis_write_data_tvalid;
        shift_axis_tlast = AXIS_LAST_ENABLE && s_axis_write_data_tlast;
        shift_axis_input_tready = 1'b1;
    end else if (!AXIS_LAST_ENABLE) begin
        shift_axis_tdata = {s_axis_write_data_tdata, save_axis_tdata_flop} >> ((AXIS_KEEP_WIDTH_INT-offset_flop)*AXIS_WORD_SIZE);
        shift_axis_tkeep = {s_axis_write_data_tkeep, save_axis_tkeep_flop} >> (AXIS_KEEP_WIDTH_INT-offset_flop);
        shift_axis_tvalid = s_axis_write_data_tvalid;
        shift_axis_tlast = 1'b0;
        shift_axis_input_tready = 1'b1;
    end else if (shift_axis_extra_cycle_flop) begin
        shift_axis_tdata = {s_axis_write_data_tdata, save_axis_tdata_flop} >> ((AXIS_KEEP_WIDTH_INT-offset_flop)*AXIS_WORD_SIZE);
        shift_axis_tkeep = {{AXIS_KEEP_WIDTH_INT{1'b0}}, save_axis_tkeep_flop} >> (AXIS_KEEP_WIDTH_INT-offset_flop);
        shift_axis_tvalid = 1'b1;
        shift_axis_tlast = save_axis_tlast_flop;
        shift_axis_input_tready = flush_save;
    end else begin
        shift_axis_tdata = {s_axis_write_data_tdata, save_axis_tdata_flop} >> ((AXIS_KEEP_WIDTH_INT-offset_flop)*AXIS_WORD_SIZE);
        shift_axis_tkeep = {s_axis_write_data_tkeep, save_axis_tkeep_flop} >> (AXIS_KEEP_WIDTH_INT-offset_flop);
        shift_axis_tvalid = s_axis_write_data_tvalid;
        shift_axis_tlast = (s_axis_write_data_tlast && ((s_axis_write_data_tkeep & ({AXIS_KEEP_WIDTH_INT{1'b1}} << (AXIS_KEEP_WIDTH_INT-offset_flop))) == 0));
        shift_axis_input_tready = !(s_axis_write_data_tlast && s_axis_write_data_tready && s_axis_write_data_tvalid);
    end
end

always_comb begin
    state_next = STATE_IDLE;

    s_axis_write_desc_ready_next = 1'b0;

    m_axis_write_desc_status_len_next = m_axis_write_desc_status_len_flop;
    m_axis_write_desc_status_tag_next = m_axis_write_desc_status_tag_flop;
    m_axis_write_desc_status_id_next = m_axis_write_desc_status_id_flop;
    m_axis_write_desc_status_dest_next = m_axis_write_desc_status_dest_flop;
    m_axis_write_desc_status_user_next = m_axis_write_desc_status_user_flop;
    m_axis_write_desc_status_valid_next = 1'b0;

    s_axis_write_data_tready_next = 1'b0;

    m_axi_awaddr_next = m_axi_awaddr_flop;
    m_axi_awlen_next = m_axi_awlen_flop;
    m_axi_awvalid_next = m_axi_awvalid_flop && !m_axi_awready;
    m_axi_wdata_int = shift_axis_tdata;
    m_axi_wstrb_int = shift_axis_tkeep;
    m_axi_wlast_int = 1'b0;
    m_axi_wvalid_int = 1'b0;
    m_axi_bready_next = 1'b0;

    transfer_in_save = 1'b0;
    flush_save = 1'b0;
    status_fifo_we = 1'b0;

    cycle_size = AXIS_KEEP_WIDTH_INT;

    addr_next = addr_flop;
    offset_next = offset_flop;
    strb_offset_mask_next = strb_offset_mask_flop;
    zero_offset_next = zero_offset_flop;
    last_cycle_offset_next = last_cycle_offset_flop;
    length_next = length_flop;
    op_word_count_next = op_word_count_flop;
    tr_word_count_next = tr_word_count_flop;
    input_cycle_count_next = input_cycle_count_flop;
    output_cycle_count_next = output_cycle_count_flop;
    input_active_next = input_active_flop;
    first_cycle_next = first_cycle_flop;
    input_last_cycle_next = input_last_cycle_flop;
    output_last_cycle_next = output_last_cycle_flop;
    last_transfer_next = last_transfer_flop;

    status_fifo_rd_ptr_next = status_fifo_rd_ptr_flop;

    inc_active = 1'b0;
    dec_active = 1'b0;

    tag_next = tag_flop;
    axis_id_next = axis_id_flop;
    axis_dest_next = axis_dest_flop;
    axis_user_next = axis_user_flop;

    status_fifo_wr_len = length_flop;
    status_fifo_wr_tag = tag_flop;
    status_fifo_wr_id = axis_id_flop;
    status_fifo_wr_dest = axis_dest_flop;
    status_fifo_wr_user = axis_user_flop;
    status_fifo_wr_last = 1'b0;

    case (state_flop)
        STATE_IDLE: begin
            // idle state - load new descriptor to start operation
            flush_save = 1'b1;
            s_axis_write_desc_ready_next = enable && active_count_av_flop;

            if (ENABLE_UNALIGNED) begin
                addr_next = s_axis_write_desc_addr;
                offset_next = s_axis_write_desc_addr & OFFSET_MASK;
                strb_offset_mask_next = {AXI_STRB_WIDTH{1'b1}} << (s_axis_write_desc_addr & OFFSET_MASK);
                zero_offset_next = (s_axis_write_desc_addr & OFFSET_MASK) == 0;
                last_cycle_offset_next = offset_next + (s_axis_write_desc_len & OFFSET_MASK);
            end else begin
                addr_next = s_axis_write_desc_addr & ADDR_MASK;
                offset_next = 0;
                strb_offset_mask_next = {AXI_STRB_WIDTH{1'b1}};
                zero_offset_next = 1'b1;
                last_cycle_offset_next = offset_next + (s_axis_write_desc_len & OFFSET_MASK);
            end
            tag_next = s_axis_write_desc_tag;
            op_word_count_next = s_axis_write_desc_len;
            first_cycle_next = 1'b1;
            length_next = 0;

            if (s_axis_write_desc_ready && s_axis_write_desc_valid) begin
                s_axis_write_desc_ready_next = 1'b0;
                state_next = STATE_START;
            end else begin
                state_next = STATE_IDLE;
            end
        end
        STATE_START: begin
            // start state - initiate new AXI transfer
            if (op_word_count_flop <= AXI_MAX_BURST_SIZE - (addr_flop & OFFSET_MASK) || AXI_MAX_BURST_SIZE >= 4096) begin
                // packet smaller than max burst size
                if (((addr_flop & 12'hfff) + (op_word_count_flop & 12'hfff)) >> 12 != 0 || op_word_count_flop >> 12 != 0) begin
                    // crosses 4k boundary
                    tr_word_count_next = 13'h1000 - (addr_flop & 12'hfff);
                end else begin
                    // does not cross 4k boundary
                    tr_word_count_next = op_word_count_flop;
                end
            end else begin
                // packet larger than max burst size
                if (((addr_flop & 12'hfff) + AXI_MAX_BURST_SIZE) >> 12 != 0) begin
                    // crosses 4k boundary
                    tr_word_count_next = 13'h1000 - (addr_flop & 12'hfff);
                end else begin
                    // does not cross 4k boundary
                    tr_word_count_next = AXI_MAX_BURST_SIZE - (addr_flop & OFFSET_MASK);
                end
            end

            input_cycle_count_next = (tr_word_count_next - 1) >> $clog2(AXIS_KEEP_WIDTH_INT);
            input_last_cycle_next = input_cycle_count_next == 0;
            if (ENABLE_UNALIGNED) begin
                output_cycle_count_next = (tr_word_count_next + (addr_flop & OFFSET_MASK) - 1) >> AXI_BURST_SIZE;
            end else begin
                output_cycle_count_next = (tr_word_count_next - 1) >> AXI_BURST_SIZE;
            end
            output_last_cycle_next = output_cycle_count_next == 0;
            last_transfer_next = tr_word_count_next == op_word_count_flop;
            input_active_next = 1'b1;

            if (ENABLE_UNALIGNED) begin
                if (!first_cycle_flop && last_transfer_next) begin
                    if (offset_flop >= last_cycle_offset_flop && last_cycle_offset_flop > 0) begin
                        // last cycle will be served by stored partial cycle
                        input_active_next = input_cycle_count_next > 0;
                        input_cycle_count_next = input_cycle_count_next - 1;
                    end
                end
            end

            if (!m_axi_awvalid_flop && active_count_av_flop) begin
                m_axi_awaddr_next = addr_flop;
                m_axi_awlen_next = output_cycle_count_next;
                m_axi_awvalid_next = s_axis_write_data_tvalid || !first_cycle_flop;

                if (m_axi_awvalid_next) begin
                    addr_next = addr_flop + tr_word_count_next;
                    op_word_count_next = op_word_count_flop - tr_word_count_next;

                    s_axis_write_data_tready_next = m_axi_wready_int_early && input_active_next;

                    inc_active = 1'b1;

                    state_next = STATE_WRITE;
                end else begin
                    state_next = STATE_START;
                end
            end else begin
                state_next = STATE_START;
            end
        end
        STATE_WRITE: begin
            s_axis_write_data_tready_next = m_axi_wready_int_early && (last_transfer_flop || input_active_flop) && shift_axis_input_tready;

            if (m_axi_wready_int_flop && ((s_axis_write_data_tready && shift_axis_tvalid) || (!input_active_flop && !last_transfer_flop) || !shift_axis_input_tready)) begin
                if (s_axis_write_data_tready && s_axis_write_data_tvalid) begin
                    transfer_in_save = 1'b1;

                    axis_id_next = s_axis_write_data_tid;
                    axis_dest_next = s_axis_write_data_tdest;
                    axis_user_next = s_axis_write_data_tuser;
                end

                // update counters
                if (first_cycle_flop) begin
                    length_next = length_flop + (AXIS_KEEP_WIDTH_INT - offset_flop);
                end else begin
                    length_next = length_flop + AXIS_KEEP_WIDTH_INT;
                end
                if (input_active_flop) begin
                    input_cycle_count_next = input_cycle_count_flop - 1;
                    input_active_next = input_cycle_count_flop > 0;
                end
                input_last_cycle_next = input_cycle_count_next == 0;
                output_cycle_count_next = output_cycle_count_flop - 1;
                output_last_cycle_next = output_cycle_count_next == 0;
                first_cycle_next = 1'b0;
                strb_offset_mask_next = {AXI_STRB_WIDTH{1'b1}};

                m_axi_wdata_int = shift_axis_tdata;
                m_axi_wstrb_int = strb_offset_mask_flop;
                m_axi_wvalid_int = 1'b1;

                if (AXIS_LAST_ENABLE && s_axis_write_data_tlast) begin
                    // end of input frame
                    input_active_next = 1'b0;
                    s_axis_write_data_tready_next = 1'b0;
                end

                if (AXIS_LAST_ENABLE && shift_axis_tlast) begin
                    // end of data packet

                    if (AXIS_KEEP_ENABLE) begin
                        cycle_size = AXIS_KEEP_WIDTH_INT;
                        for (i = AXIS_KEEP_WIDTH_INT-1; i >= 0; i = i - 1) begin
                            if (~shift_axis_tkeep & strb_offset_mask_flop & (1 << i)) begin
                                cycle_size = i;
                            end
                        end
                    end else begin
                        cycle_size = AXIS_KEEP_WIDTH_INT;
                    end

                    if (output_last_cycle_flop) begin
                        m_axi_wlast_int = 1'b1;

                        // no more data to transfer, finish operation
                        if (last_transfer_flop && last_cycle_offset_flop > 0) begin
                            if (AXIS_KEEP_ENABLE && !(shift_axis_tkeep & ~({AXI_STRB_WIDTH{1'b1}} >> (AXI_STRB_WIDTH - last_cycle_offset_flop)))) begin
                                m_axi_wstrb_int = strb_offset_mask_flop & shift_axis_tkeep;
                                if (first_cycle_flop) begin
                                    length_next = length_flop + (cycle_size - offset_flop);
                                end else begin
                                    length_next = length_flop + cycle_size;
                                end
                            end else begin
                                m_axi_wstrb_int = strb_offset_mask_flop & {AXI_STRB_WIDTH{1'b1}} >> (AXI_STRB_WIDTH - last_cycle_offset_flop);
                                if (first_cycle_flop) begin
                                    length_next = length_flop + (last_cycle_offset_flop - offset_flop);
                                end else begin
                                    length_next = length_flop + last_cycle_offset_flop;
                                end
                            end
                        end else begin
                            if (AXIS_KEEP_ENABLE) begin
                                m_axi_wstrb_int = strb_offset_mask_flop & shift_axis_tkeep;
                                if (first_cycle_flop) begin
                                    length_next = length_flop + (cycle_size - offset_flop);
                                end else begin
                                    length_next = length_flop + cycle_size;
                                end
                            end
                        end

                        // enqueue status FIFO entry for write completion
                        status_fifo_we = 1'b1;
                        status_fifo_wr_len = length_next;
                        status_fifo_wr_tag = tag_flop;
                        status_fifo_wr_id = axis_id_next;
                        status_fifo_wr_dest = axis_dest_next;
                        status_fifo_wr_user = axis_user_next;
                        status_fifo_wr_last = 1'b1;

                        s_axis_write_data_tready_next = 1'b0;
                        s_axis_write_desc_ready_next = enable && active_count_av_flop;
                        state_next = STATE_IDLE;
                    end else begin
                        // more cycles left in burst, finish burst
                        if (AXIS_KEEP_ENABLE) begin
                            m_axi_wstrb_int = strb_offset_mask_flop & shift_axis_tkeep;
                            if (first_cycle_flop) begin
                                length_next = length_flop + (cycle_size - offset_flop);
                            end else begin
                                length_next = length_flop + cycle_size;
                            end
                        end

                        // enqueue status FIFO entry for write completion
                        status_fifo_we = 1'b1;
                        status_fifo_wr_len = length_next;
                        status_fifo_wr_tag = tag_flop;
                        status_fifo_wr_id = axis_id_next;
                        status_fifo_wr_dest = axis_dest_next;
                        status_fifo_wr_user = axis_user_next;
                        status_fifo_wr_last = 1'b1;

                        s_axis_write_data_tready_next = 1'b0;
                        state_next = STATE_FINISH_BURST;
                    end

                end else if (output_last_cycle_flop) begin
                    m_axi_wlast_int = 1'b1;

                    if (op_word_count_flop > 0) begin
                        // current AXI transfer complete, but there is more data to transfer
                        // enqueue status FIFO entry for write completion
                        status_fifo_we = 1'b1;
                        status_fifo_wr_len = length_next;
                        status_fifo_wr_tag = tag_flop;
                        status_fifo_wr_id = axis_id_next;
                        status_fifo_wr_dest = axis_dest_next;
                        status_fifo_wr_user = axis_user_next;
                        status_fifo_wr_last = 1'b0;

                        s_axis_write_data_tready_next = 1'b0;
                        state_next = STATE_START;
                    end else begin
                        // no more data to transfer, finish operation
                        if (last_cycle_offset_flop > 0) begin
                            m_axi_wstrb_int = strb_offset_mask_flop & {AXI_STRB_WIDTH{1'b1}} >> (AXI_STRB_WIDTH - last_cycle_offset_flop);
                            if (first_cycle_flop) begin
                                length_next = length_flop + (last_cycle_offset_flop - offset_flop);
                            end else begin
                                length_next = length_flop + last_cycle_offset_flop;
                            end
                        end

                        // enqueue status FIFO entry for write completion
                        status_fifo_we = 1'b1;
                        status_fifo_wr_len = length_next;
                        status_fifo_wr_tag = tag_flop;
                        status_fifo_wr_id = axis_id_next;
                        status_fifo_wr_dest = axis_dest_next;
                        status_fifo_wr_user = axis_user_next;
                        status_fifo_wr_last = 1'b1;

                        if (AXIS_LAST_ENABLE) begin
                            // not at the end of packet; drop remainder
                            s_axis_write_data_tready_next = shift_axis_input_tready;
                            state_next = STATE_DROP_DATA;
                        end else begin
                            // no framing; return to idle
                            s_axis_write_data_tready_next = 1'b0;
                            s_axis_write_desc_ready_next = enable && active_count_av_flop;
                            state_next = STATE_IDLE;
                        end
                    end
                end else begin
                    s_axis_write_data_tready_next = m_axi_wready_int_early && (last_transfer_flop || input_active_next) && shift_axis_input_tready;
                    state_next = STATE_WRITE;
                end
            end else begin
                state_next = STATE_WRITE;
            end
        end
        STATE_FINISH_BURST: begin
            // finish current AXI burst

            if (m_axi_wready_int_flop) begin
                // update counters
                if (input_active_flop) begin
                    input_cycle_count_next = input_cycle_count_flop - 1;
                    input_active_next = input_cycle_count_flop > 0;
                end
                input_last_cycle_next = input_cycle_count_next == 0;
                output_cycle_count_next = output_cycle_count_flop - 1;
                output_last_cycle_next = output_cycle_count_next == 0;

                m_axi_wdata_int = {AXI_DATA_WIDTH{1'b0}};
                m_axi_wstrb_int = {AXI_STRB_WIDTH{1'b0}};
                m_axi_wvalid_int = 1'b1;

                if (output_last_cycle_flop) begin
                    // no more data to transfer, finish operation
                    m_axi_wlast_int = 1'b1;

                    s_axis_write_data_tready_next = 1'b0;
                    s_axis_write_desc_ready_next = enable && active_count_av_flop;
                    state_next = STATE_IDLE;
                end else begin
                    // more cycles in AXI transfer
                    state_next = STATE_FINISH_BURST;
                end
            end else begin
                state_next = STATE_FINISH_BURST;
            end
        end
        STATE_DROP_DATA: begin
            // drop excess AXI stream data
            s_axis_write_data_tready_next = shift_axis_input_tready;

            if (shift_axis_tvalid) begin
                if (s_axis_write_data_tready && s_axis_write_data_tvalid) begin
                    transfer_in_save = 1'b1;
                end

                if (shift_axis_tlast) begin
                    s_axis_write_data_tready_next = 1'b0;
                    s_axis_write_desc_ready_next = enable && active_count_av_flop;
                    state_next = STATE_IDLE;
                end else begin
                    state_next = STATE_DROP_DATA;
                end
            end else begin
                state_next = STATE_DROP_DATA;
            end
        end
    endcase

    if (status_fifo_rd_ptr_flop != status_fifo_wr_ptr_flop) begin
        // status FIFO not empty
        if (m_axi_bready && m_axi_bvalid) begin
            // got write completion, pop and return status
            m_axis_write_desc_status_len_next = status_fifo_len[status_fifo_rd_ptr_flop[STATUS_FIFO_ADDR_WIDTH-1:0]];
            m_axis_write_desc_status_tag_next = status_fifo_tag[status_fifo_rd_ptr_flop[STATUS_FIFO_ADDR_WIDTH-1:0]];
            m_axis_write_desc_status_id_next = status_fifo_id[status_fifo_rd_ptr_flop[STATUS_FIFO_ADDR_WIDTH-1:0]];
            m_axis_write_desc_status_dest_next = status_fifo_dest[status_fifo_rd_ptr_flop[STATUS_FIFO_ADDR_WIDTH-1:0]];
            m_axis_write_desc_status_user_next = status_fifo_user[status_fifo_rd_ptr_flop[STATUS_FIFO_ADDR_WIDTH-1:0]];
            m_axis_write_desc_status_valid_next = status_fifo_last[status_fifo_rd_ptr_flop[STATUS_FIFO_ADDR_WIDTH-1:0]];
            status_fifo_rd_ptr_next = status_fifo_rd_ptr_flop + 1;
            m_axi_bready_next = 1'b0;

            dec_active = 1'b1;
        end else begin
            // wait for write completion
            m_axi_bready_next = 1'b1;
        end
    end
end
/*
   Patch Start
*/
always_comb begin
    save_axis_tkeep_flop_next = save_axis_tkeep_flop;
    save_axis_tdata_flop_next = save_axis_tdata_flop;
    save_axis_tlast_flop_next = save_axis_tlast_flop;
    shift_axis_extra_cycle_flop_next = shift_axis_extra_cycle_flop;
    if (flush_save) begin
        save_axis_tkeep_flop_next = {AXIS_KEEP_WIDTH_INT{1'b0}};
        save_axis_tlast_flop_next = 1'b0;
        shift_axis_extra_cycle_flop_next = 1'b0;
    end else if (transfer_in_save) begin
        save_axis_tdata_flop_next = s_axis_write_data_tdata;
        save_axis_tkeep_flop_next = AXIS_KEEP_ENABLE ? s_axis_write_data_tkeep : {AXIS_KEEP_WIDTH_INT{1'b1}};
        save_axis_tlast_flop_next = s_axis_write_data_tlast;
        shift_axis_extra_cycle_flop_next = s_axis_write_data_tlast & ((s_axis_write_data_tkeep >> (AXIS_KEEP_WIDTH_INT-offset_flop)) != 0);
    end
end
always_comb begin
     status_fifo_len_next = status_fifo_len;
     status_fifo_tag_next = status_fifo_tag;
     status_fifo_id_next = status_fifo_id;
     status_fifo_dest_next = status_fifo_dest;
     status_fifo_user_next = status_fifo_user;
     status_fifo_last_next = status_fifo_last;
     status_fifo_wr_ptr_flop_next = status_fifo_wr_ptr_flop;
    if (status_fifo_we) begin
        status_fifo_len_next[status_fifo_wr_ptr_flop[STATUS_FIFO_ADDR_WIDTH-1:0]] = status_fifo_wr_len;
        status_fifo_tag_next[status_fifo_wr_ptr_flop[STATUS_FIFO_ADDR_WIDTH-1:0]] = status_fifo_wr_tag;
        status_fifo_id_next[status_fifo_wr_ptr_flop[STATUS_FIFO_ADDR_WIDTH-1:0]] = status_fifo_wr_id;
        status_fifo_dest_next[status_fifo_wr_ptr_flop[STATUS_FIFO_ADDR_WIDTH-1:0]] = status_fifo_wr_dest;
        status_fifo_user_next[status_fifo_wr_ptr_flop[STATUS_FIFO_ADDR_WIDTH-1:0]] = status_fifo_wr_user;
        status_fifo_last_next[status_fifo_wr_ptr_flop[STATUS_FIFO_ADDR_WIDTH-1:0]] = status_fifo_wr_last;
        status_fifo_wr_ptr_flop_next = status_fifo_wr_ptr_flop + 1;
    end
end
always_comb begin   
   active_count_flop_next = active_count_flop; 
   active_count_av_flop_next = active_count_av_flop; 
   if (active_count_flop < 2**STATUS_FIFO_ADDR_WIDTH && inc_active && !dec_active) begin
        active_count_flop_next = active_count_flop + 1;
        active_count_av_flop_next = active_count_flop < (2**STATUS_FIFO_ADDR_WIDTH-1);
    end else if (active_count_flop > 0 && !inc_active && dec_active) begin
        active_count_flop_next = active_count_flop - 1;
        active_count_av_flop_next = 1'b1;
    end else begin
        active_count_av_flop_next = active_count_flop < 2**STATUS_FIFO_ADDR_WIDTH;
    end
end
/*
   Patch End
*/



always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        state_flop <= STATE_IDLE;

        s_axis_write_desc_ready_flop <= 1'b0;

    m_axis_write_desc_status_len_flop <= 0;
    m_axis_write_desc_status_tag_flop <= 0;
    m_axis_write_desc_status_id_flop <= 0;
    m_axis_write_desc_status_dest_flop <= 0;
    m_axis_write_desc_status_user_flop <= 0;
        m_axis_write_desc_status_valid_flop <= 1'b0;

        s_axis_write_data_tready_flop <= 1'b0;

    m_axi_awaddr_flop <= 0;
    m_axi_awlen_flop <= 0;
        m_axi_awvalid_flop <= 1'b0;
        m_axi_bready_flop <= 1'b0;

    addr_flop <= 0;
    offset_flop <= 0;
    strb_offset_mask_flop <= 0;
    zero_offset_flop <= 1;
    last_cycle_offset_flop <= 0;
    length_flop <= 0;
    op_word_count_flop <= 0;
    tr_word_count_flop <= 0;
    input_cycle_count_flop <= 0;
    output_cycle_count_flop <= 0;
    input_active_flop <= 0;
    first_cycle_flop <= 0;
    input_last_cycle_flop <= 0;
    output_last_cycle_flop <= 0;
    last_transfer_flop <= 0;

    tag_flop <= 0;
    axis_id_flop <= 0;
    axis_dest_flop <= 0;
    axis_user_flop <= 0;
    
    save_axis_tkeep_flop <= 0;
    save_axis_tdata_flop <= 0;
     save_axis_tlast_flop <= 1'b0;
        shift_axis_extra_cycle_flop <= 1'b0;

     status_fifo_len <= 0;
     status_fifo_tag <= 0;
     status_fifo_id <= 0;
     status_fifo_dest <= 0;
     status_fifo_user <= 0;
     status_fifo_last <= 0;
        status_fifo_wr_ptr_flop <= 0;
        status_fifo_rd_ptr_flop <= 0;

        active_count_flop <= 0;
        active_count_av_flop <= 1'b1;
    end
    else begin
    state_flop <= state_next;

    s_axis_write_desc_ready_flop <= s_axis_write_desc_ready_next;

    m_axis_write_desc_status_len_flop <= m_axis_write_desc_status_len_next;
    m_axis_write_desc_status_tag_flop <= m_axis_write_desc_status_tag_next;
    m_axis_write_desc_status_id_flop <= m_axis_write_desc_status_id_next;
    m_axis_write_desc_status_dest_flop <= m_axis_write_desc_status_dest_next;
    m_axis_write_desc_status_user_flop <= m_axis_write_desc_status_user_next;
    m_axis_write_desc_status_valid_flop <= m_axis_write_desc_status_valid_next;

    s_axis_write_data_tready_flop <= s_axis_write_data_tready_next;

    m_axi_awaddr_flop <= m_axi_awaddr_next;
    m_axi_awlen_flop <= m_axi_awlen_next;
    m_axi_awvalid_flop <= m_axi_awvalid_next;
    m_axi_bready_flop <= m_axi_bready_next;

    addr_flop <= addr_next;
    offset_flop <= offset_next;
    strb_offset_mask_flop <= strb_offset_mask_next;
    zero_offset_flop <= zero_offset_next;
    last_cycle_offset_flop <= last_cycle_offset_next;
    length_flop <= length_next;
    op_word_count_flop <= op_word_count_next;
    tr_word_count_flop <= tr_word_count_next;
    input_cycle_count_flop <= input_cycle_count_next;
    output_cycle_count_flop <= output_cycle_count_next;
    input_active_flop <= input_active_next;
    first_cycle_flop <= first_cycle_next;
    input_last_cycle_flop <= input_last_cycle_next;
    output_last_cycle_flop <= output_last_cycle_next;
    last_transfer_flop <= last_transfer_next;

    tag_flop <= tag_next;
    axis_id_flop <= axis_id_next;
    axis_dest_flop <= axis_dest_next;
    axis_user_flop <= axis_user_next;

    save_axis_tkeep_flop <= save_axis_tkeep_flop_next;
    save_axis_tdata_flop <= save_axis_tdata_flop_next;
    save_axis_tlast_flop <= save_axis_tlast_flop_next;
    shift_axis_extra_cycle_flop <= shift_axis_extra_cycle_flop_next;
    
     status_fifo_len <= status_fifo_len_next;
     status_fifo_tag <= status_fifo_tag_next;
     status_fifo_id <= status_fifo_id_next;
     status_fifo_dest <= status_fifo_dest_next;
     status_fifo_user <= status_fifo_user_next;
     status_fifo_last <= status_fifo_last_next;
     status_fifo_wr_ptr_flop <= status_fifo_wr_ptr_flop_next;
    status_fifo_rd_ptr_flop <= status_fifo_rd_ptr_next;
   
   active_count_flop <= active_count_flop_next; 
   active_count_av_flop <= active_count_av_flop_next; 
   end
    // datapath
/*
    if (flush_save) begin
        save_axis_tkeep_flop <= {AXIS_KEEP_WIDTH_INT{1'b0}};
        save_axis_tlast_flop <= 1'b0;
        shift_axis_extra_cycle_flop <= 1'b0;
    end else if (transfer_in_save) begin
        save_axis_tdata_flop <= s_axis_write_data_tdata;
        save_axis_tkeep_flop <= AXIS_KEEP_ENABLE ? s_axis_write_data_tkeep : {AXIS_KEEP_WIDTH_INT{1'b1}};
        save_axis_tlast_flop <= s_axis_write_data_tlast;
        shift_axis_extra_cycle_flop <= s_axis_write_data_tlast & ((s_axis_write_data_tkeep >> (AXIS_KEEP_WIDTH_INT-offset_flop)) != 0);
    end
*/
/*
    if (status_fifo_we) begin
        status_fifo_len[status_fifo_wr_ptr_flop[STATUS_FIFO_ADDR_WIDTH-1:0]] <= status_fifo_wr_len;
        status_fifo_tag[status_fifo_wr_ptr_flop[STATUS_FIFO_ADDR_WIDTH-1:0]] <= status_fifo_wr_tag;
        status_fifo_id[status_fifo_wr_ptr_flop[STATUS_FIFO_ADDR_WIDTH-1:0]] <= status_fifo_wr_id;
        status_fifo_dest[status_fifo_wr_ptr_flop[STATUS_FIFO_ADDR_WIDTH-1:0]] <= status_fifo_wr_dest;
        status_fifo_user[status_fifo_wr_ptr_flop[STATUS_FIFO_ADDR_WIDTH-1:0]] <= status_fifo_wr_user;
        status_fifo_last[status_fifo_wr_ptr_flop[STATUS_FIFO_ADDR_WIDTH-1:0]] <= status_fifo_wr_last;
        status_fifo_wr_ptr_flop <= status_fifo_wr_ptr_flop + 1;
    end
*/
/*
    if (active_count_flop < 2**STATUS_FIFO_ADDR_WIDTH && inc_active && !dec_active) begin
        active_count_flop <= active_count_flop + 1;
        active_count_av_flop <= active_count_flop < (2**STATUS_FIFO_ADDR_WIDTH-1);
    end else if (active_count_flop > 0 && !inc_active && dec_active) begin
        active_count_flop <= active_count_flop - 1;
        active_count_av_flop <= 1'b1;
    end else begin
        active_count_av_flop <= active_count_flop < 2**STATUS_FIFO_ADDR_WIDTH;
    end
*/
end

// output datapath logic
logic [AXI_DATA_WIDTH-1:0] m_axi_wdata_flop, m_axi_wdata_flop_next;
logic [AXI_STRB_WIDTH-1:0] m_axi_wstrb_flop, m_axi_wstrb_flop_next;
logic                      m_axi_wlast_flop, m_axi_wlast_flop_next;
logic                      m_axi_wvalid_flop, m_axi_wvalid_next;

logic [AXI_DATA_WIDTH-1:0] temp_m_axi_wdata_flop, temp_m_axi_wdata_flop_next;
logic [AXI_STRB_WIDTH-1:0] temp_m_axi_wstrb_flop, temp_m_axi_wstrb_flop_next;
logic                      temp_m_axi_wlast_flop, temp_m_axi_wlast_flop_next;
logic                      temp_m_axi_wvalid_flop, temp_m_axi_wvalid_next;

// datapath control
logic store_axi_w_int_to_output;
logic store_axi_w_int_to_temp;
logic store_axi_w_temp_to_output;

assign m_axi_wdata  = m_axi_wdata_flop;
assign m_axi_wstrb  = m_axi_wstrb_flop;
assign m_axi_wvalid = m_axi_wvalid_flop;
assign m_axi_wlast  = m_axi_wlast_flop;

// enable ready input next cycle if output is ready or the temp logic will not be filled on the next cycle (output logic empty or no input)
assign m_axi_wready_int_early = m_axi_wready || (!temp_m_axi_wvalid_flop && (!m_axi_wvalid_flop || !m_axi_wvalid_int));

always_comb begin
    // transfer sink ready state to source
    m_axi_wvalid_next = m_axi_wvalid_flop;
    temp_m_axi_wvalid_next = temp_m_axi_wvalid_flop;

    store_axi_w_int_to_output = 1'b0;
    store_axi_w_int_to_temp = 1'b0;
    store_axi_w_temp_to_output = 1'b0;

    if (m_axi_wready_int_flop) begin
        // input is ready
        if (m_axi_wready || !m_axi_wvalid_flop) begin
            // output is ready or currently not valid, transfer data to output
            m_axi_wvalid_next = m_axi_wvalid_int;
            store_axi_w_int_to_output = 1'b1;
        end else begin
            // output is not ready, store input in temp
            temp_m_axi_wvalid_next = m_axi_wvalid_int;
            store_axi_w_int_to_temp = 1'b1;
        end
    end else if (m_axi_wready) begin
        // input is not ready, but output is ready
        m_axi_wvalid_next = temp_m_axi_wvalid_flop;
        temp_m_axi_wvalid_next = 1'b0;
        store_axi_w_temp_to_output = 1'b1;
    end
end
/*
   patch starts
*/
always_comb begin
    m_axi_wdata_flop_next = m_axi_wdata_flop;
    m_axi_wstrb_flop_next = m_axi_wstrb_flop;
    m_axi_wlast_flop_next = m_axi_wlast_flop;
    if (store_axi_w_int_to_output) begin
        m_axi_wdata_flop_next = m_axi_wdata_int;
        m_axi_wstrb_flop_next = m_axi_wstrb_int;
        m_axi_wlast_flop_next = m_axi_wlast_int;
    end else if (store_axi_w_temp_to_output) begin
        m_axi_wdata_flop_next = temp_m_axi_wdata_flop;
        m_axi_wstrb_flop_next = temp_m_axi_wstrb_flop;
        m_axi_wlast_flop_next = temp_m_axi_wlast_flop;
    end
end
always_comb begin
        temp_m_axi_wdata_flop_next = temp_m_axi_wdata_flop;
        temp_m_axi_wstrb_flop_next = temp_m_axi_wstrb_flop;
        temp_m_axi_wlast_flop_next = temp_m_axi_wlast_flop;
    if (store_axi_w_int_to_temp) begin
        temp_m_axi_wdata_flop_next = m_axi_wdata_int;
        temp_m_axi_wstrb_flop_next = m_axi_wstrb_int;
        temp_m_axi_wlast_flop_next = m_axi_wlast_int;
    end
end
/*
   patch ends
*/


always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        m_axi_wvalid_flop <= 1'b0;
        m_axi_wready_int_flop <= 1'b0;
        temp_m_axi_wvalid_flop <= 1'b0;
    m_axi_wdata_flop <= 0;
    m_axi_wstrb_flop <= 0;
    m_axi_wlast_flop <= 0;

        temp_m_axi_wdata_flop <= 0;
        temp_m_axi_wstrb_flop <= 0;
        temp_m_axi_wlast_flop <= 0;
    end else begin
        m_axi_wvalid_flop <= m_axi_wvalid_next;
        m_axi_wready_int_flop <= m_axi_wready_int_early;
        temp_m_axi_wvalid_flop <= temp_m_axi_wvalid_next;
    m_axi_wdata_flop <= m_axi_wdata_flop_next;
    m_axi_wstrb_flop <= m_axi_wstrb_flop_next;
    m_axi_wlast_flop <= m_axi_wlast_flop_next;

        temp_m_axi_wdata_flop <= temp_m_axi_wdata_flop_next;
        temp_m_axi_wstrb_flop <= temp_m_axi_wstrb_flop_next;
        temp_m_axi_wlast_flop <= temp_m_axi_wlast_flop_next;
    end
/*
    // datapath
    if (store_axi_w_int_to_output) begin
        m_axi_wdata_flop <= m_axi_wdata_int;
        m_axi_wstrb_flop <= m_axi_wstrb_int;
        m_axi_wlast_flop <= m_axi_wlast_int;
    end else if (store_axi_w_temp_to_output) begin
        m_axi_wdata_flop <= temp_m_axi_wdata_flop;
        m_axi_wstrb_flop <= temp_m_axi_wstrb_flop;
        m_axi_wlast_flop <= temp_m_axi_wlast_flop;
    end

    if (store_axi_w_int_to_temp) begin
        temp_m_axi_wdata_flop <= m_axi_wdata_int;
        temp_m_axi_wstrb_flop <= m_axi_wstrb_int;
        temp_m_axi_wlast_flop <= m_axi_wlast_int;
    end
*/
end

endmodule
