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
module axi_dma_rd #
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
    input                                clk,
    input                                rst,

    /*
     * AXI read descriptor input
     */
    input          [AXI_ADDR_WIDTH-1:0]  s_axis_read_desc_addr,
    input          [LEN_WIDTH-1:0]       s_axis_read_desc_len,
    input          [TAG_WIDTH-1:0]       s_axis_read_desc_tag,
    input          [AXIS_ID_WIDTH-1:0]   s_axis_read_desc_id,
    input          [AXIS_DEST_WIDTH-1:0] s_axis_read_desc_dest,
    input          [AXIS_USER_WIDTH-1:0] s_axis_read_desc_user,
    input                                s_axis_read_desc_valid,
    output   logic                       s_axis_read_desc_ready,

    /*
     * AXI read descriptor status output
     */
    output   logic [TAG_WIDTH-1:0]       m_axis_read_desc_status_tag,
    output   logic                       m_axis_read_desc_status_valid,

    /*
     * AXI stream read data output
     */
    output   logic [AXIS_DATA_WIDTH-1:0] m_axis_read_data_tdata,
    output   logic [AXIS_KEEP_WIDTH-1:0] m_axis_read_data_tkeep,
    output   logic                       m_axis_read_data_tvalid,
    input                                m_axis_read_data_tready,
    output   logic                       m_axis_read_data_tlast,
    output   logic [AXIS_ID_WIDTH-1:0]   m_axis_read_data_tid,
    output   logic [AXIS_DEST_WIDTH-1:0] m_axis_read_data_tdest,
    output   logic [AXIS_USER_WIDTH-1:0] m_axis_read_data_tuser,

    /*
     * AXI master interface
     */
    output   logic [AXI_ID_WIDTH-1:0]    m_axi_arid,
    output   logic [AXI_ADDR_WIDTH-1:0]  m_axi_araddr,
    output   logic [7:0]                 m_axi_arlen,
    output   logic [2:0]                 m_axi_arsize,
    output   logic [1:0]                 m_axi_arburst,
    output   logic                       m_axi_arlock,
    output   logic [3:0]                 m_axi_arcache,
    output   logic [2:0]                 m_axi_arprot,
    output   logic                       m_axi_arvalid,
    input                                m_axi_arready,
    input          [AXI_ID_WIDTH-1:0]    m_axi_rid,
    input          [AXI_DATA_WIDTH-1:0]  m_axi_rdata,
    input          [1:0]                 m_axi_rresp,
    input                                m_axi_rlast,
    input                                m_axi_rvalid,
    output   logic                       m_axi_rready,

    /*
     * Configuration
     */
    input                                enable
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

// bus width assertions

localparam [0:0]
    AXI_STATE_IDLE = 1'd0,
    AXI_STATE_START = 1'd1;

logic [0:0] axi_state_flop, axi_state_next;

localparam [0:0]
    AXIS_STATE_IDLE = 1'd0,
    AXIS_STATE_READ = 1'd1;

logic [0:0] axis_state_flop, axis_state_next;

// datapath control signals
logic transfer_in_save;
logic axis_cmd_ready;

logic [AXI_ADDR_WIDTH-1:0] addr_flop, addr_next;
logic [LEN_WIDTH-1:0] op_word_count_flop, op_word_count_next;
logic [LEN_WIDTH-1:0] tr_word_count_flop, tr_word_count_next;

logic [OFFSET_WIDTH-1:0] axis_cmd_offset_flop, axis_cmd_offset_next;
logic [OFFSET_WIDTH-1:0] axis_cmd_last_cycle_offset_flop, axis_cmd_last_cycle_offset_next;
logic [CYCLE_COUNT_WIDTH-1:0] axis_cmd_input_cycle_count_flop, axis_cmd_input_cycle_count_next;
logic [CYCLE_COUNT_WIDTH-1:0] axis_cmd_output_cycle_count_flop, axis_cmd_output_cycle_count_next;
logic axis_cmd_bubble_cycle_flop, axis_cmd_bubble_cycle_next;
logic [TAG_WIDTH-1:0] axis_cmd_tag_flop, axis_cmd_tag_next;
logic [AXIS_ID_WIDTH-1:0] axis_cmd_axis_id_flop, axis_cmd_axis_id_next;
logic [AXIS_DEST_WIDTH-1:0] axis_cmd_axis_dest_flop, axis_cmd_axis_dest_next;
logic [AXIS_USER_WIDTH-1:0] axis_cmd_axis_user_flop, axis_cmd_axis_user_next;
logic axis_cmd_valid_flop, axis_cmd_valid_next;

logic [OFFSET_WIDTH-1:0] offset_flop, offset_next;
logic [OFFSET_WIDTH-1:0] last_cycle_offset_flop, last_cycle_offset_next;
logic [CYCLE_COUNT_WIDTH-1:0] input_cycle_count_flop, input_cycle_count_next;
logic [CYCLE_COUNT_WIDTH-1:0] output_cycle_count_flop, output_cycle_count_next;
logic input_active_flop, input_active_next;
logic output_active_flop, output_active_next;
logic bubble_cycle_flop, bubble_cycle_next;
logic first_cycle_flop, first_cycle_next;
logic output_last_cycle_flop, output_last_cycle_next;

logic [TAG_WIDTH-1:0] tag_flop, tag_next;
logic [AXIS_ID_WIDTH-1:0] axis_id_flop, axis_id_next;
logic [AXIS_DEST_WIDTH-1:0] axis_dest_flop, axis_dest_next;
logic [AXIS_USER_WIDTH-1:0] axis_user_flop, axis_user_next;

logic s_axis_read_desc_ready_flop, s_axis_read_desc_ready_next;

logic [TAG_WIDTH-1:0] m_axis_read_desc_status_tag_flop, m_axis_read_desc_status_tag_next;
logic m_axis_read_desc_status_valid_flop, m_axis_read_desc_status_valid_next;

logic [AXI_ADDR_WIDTH-1:0] m_axi_araddr_flop, m_axi_araddr_next;
logic [7:0] m_axi_arlen_flop, m_axi_arlen_next;
logic m_axi_arvalid_flop, m_axi_arvalid_next;
logic m_axi_rready_flop, m_axi_rready_next;

logic [AXI_DATA_WIDTH-1:0] save_axi_rdata_flop, save_axi_rdata_flop_next;

logic [AXI_DATA_WIDTH-1:0] shift_axi_rdata;
assign  shift_axi_rdata = {m_axi_rdata, save_axi_rdata_flop} >> ((AXI_STRB_WIDTH-offset_flop)*AXI_WORD_SIZE);

// internal datapath
logic  [AXIS_DATA_WIDTH-1:0] m_axis_read_data_tdata_int;
logic  [AXIS_KEEP_WIDTH-1:0] m_axis_read_data_tkeep_int;
logic                        m_axis_read_data_tvalid_int;
logic                        m_axis_read_data_tready_int_flop;
logic                        m_axis_read_data_tlast_int;
logic  [AXIS_ID_WIDTH-1:0]   m_axis_read_data_tid_int;
logic  [AXIS_DEST_WIDTH-1:0] m_axis_read_data_tdest_int;
logic  [AXIS_USER_WIDTH-1:0] m_axis_read_data_tuser_int;
wire                       m_axis_read_data_tready_int_early;

assign s_axis_read_desc_ready = s_axis_read_desc_ready_flop;

assign m_axis_read_desc_status_tag = m_axis_read_desc_status_tag_flop;
assign m_axis_read_desc_status_valid = m_axis_read_desc_status_valid_flop;

assign m_axi_arid = {AXI_ID_WIDTH{1'b0}};
assign m_axi_araddr = m_axi_araddr_flop;
assign m_axi_arlen = m_axi_arlen_flop;
assign m_axi_arsize = AXI_BURST_SIZE;
assign m_axi_arburst = 2'b01;
assign m_axi_arlock = 1'b0;
assign m_axi_arcache = 4'b0011;
assign m_axi_arprot = 3'b010;
assign m_axi_arvalid = m_axi_arvalid_flop;
assign m_axi_rready = m_axi_rready_flop;

always_comb begin
    axi_state_next = AXI_STATE_IDLE;

    s_axis_read_desc_ready_next = 1'b0;

    m_axi_araddr_next = m_axi_araddr_flop;
    m_axi_arlen_next = m_axi_arlen_flop;
    m_axi_arvalid_next = m_axi_arvalid_flop && !m_axi_arready;

    addr_next = addr_flop;
    op_word_count_next = op_word_count_flop;
    tr_word_count_next = tr_word_count_flop;

    axis_cmd_offset_next = axis_cmd_offset_flop;
    axis_cmd_last_cycle_offset_next = axis_cmd_last_cycle_offset_flop;
    axis_cmd_input_cycle_count_next = axis_cmd_input_cycle_count_flop;
    axis_cmd_output_cycle_count_next = axis_cmd_output_cycle_count_flop;
    axis_cmd_bubble_cycle_next = axis_cmd_bubble_cycle_flop;
    axis_cmd_tag_next = axis_cmd_tag_flop;
    axis_cmd_axis_id_next = axis_cmd_axis_id_flop;
    axis_cmd_axis_dest_next = axis_cmd_axis_dest_flop;
    axis_cmd_axis_user_next = axis_cmd_axis_user_flop;
    axis_cmd_valid_next = axis_cmd_valid_flop && !axis_cmd_ready;

    case (axi_state_flop)
        AXI_STATE_IDLE: begin
            // idle state - load new descriptor to start operation
            s_axis_read_desc_ready_next = !axis_cmd_valid_flop && enable;

            if (s_axis_read_desc_ready && s_axis_read_desc_valid) begin
                if (ENABLE_UNALIGNED) begin
                    addr_next = s_axis_read_desc_addr;
                    axis_cmd_offset_next = AXI_STRB_WIDTH > 1 ? AXI_STRB_WIDTH - (s_axis_read_desc_addr & OFFSET_MASK) : 0;
                    axis_cmd_bubble_cycle_next = axis_cmd_offset_next > 0;
                    axis_cmd_last_cycle_offset_next = s_axis_read_desc_len & OFFSET_MASK;
                end else begin
                    addr_next = s_axis_read_desc_addr & ADDR_MASK;
                    axis_cmd_offset_next = 0;
                    axis_cmd_bubble_cycle_next = 1'b0;
                    axis_cmd_last_cycle_offset_next = s_axis_read_desc_len & OFFSET_MASK;
                end
                axis_cmd_tag_next = s_axis_read_desc_tag;
                op_word_count_next = s_axis_read_desc_len;

                axis_cmd_axis_id_next = s_axis_read_desc_id;
                axis_cmd_axis_dest_next = s_axis_read_desc_dest;
                axis_cmd_axis_user_next = s_axis_read_desc_user;

                if (ENABLE_UNALIGNED) begin
                    axis_cmd_input_cycle_count_next = (op_word_count_next + (s_axis_read_desc_addr & OFFSET_MASK) - 1) >> AXI_BURST_SIZE;
                end else begin
                    axis_cmd_input_cycle_count_next = (op_word_count_next - 1) >> AXI_BURST_SIZE;
                end
                axis_cmd_output_cycle_count_next = (op_word_count_next - 1) >> AXI_BURST_SIZE;

                axis_cmd_valid_next = 1'b1;

                s_axis_read_desc_ready_next = 1'b0;
                axi_state_next = AXI_STATE_START;
            end else begin
                axi_state_next = AXI_STATE_IDLE;
            end
        end
        AXI_STATE_START: begin
            // start state - initiate new AXI transfer
            if (!m_axi_arvalid) begin
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

                m_axi_araddr_next = addr_flop;
                if (ENABLE_UNALIGNED) begin
                    m_axi_arlen_next = (tr_word_count_next + (addr_flop & OFFSET_MASK) - 1) >> AXI_BURST_SIZE;
                end else begin
                    m_axi_arlen_next = (tr_word_count_next - 1) >> AXI_BURST_SIZE;
                end
                m_axi_arvalid_next = 1'b1;

                addr_next = addr_flop + tr_word_count_next;
                op_word_count_next = op_word_count_flop - tr_word_count_next;

                if (op_word_count_next > 0) begin
                    axi_state_next = AXI_STATE_START;
                end else begin
                    s_axis_read_desc_ready_next = !axis_cmd_valid_flop && enable;
                    axi_state_next = AXI_STATE_IDLE;
                end
            end else begin
                axi_state_next = AXI_STATE_START;
            end
        end
    endcase
end

always_comb begin
    axis_state_next = AXIS_STATE_IDLE;

    m_axis_read_desc_status_tag_next = m_axis_read_desc_status_tag_flop;
    m_axis_read_desc_status_valid_next = 1'b0;

    m_axis_read_data_tdata_int = shift_axi_rdata;
    m_axis_read_data_tkeep_int = {AXIS_KEEP_WIDTH{1'b1}};
    m_axis_read_data_tlast_int = 1'b0;
    m_axis_read_data_tvalid_int = 1'b0;
    m_axis_read_data_tid_int = axis_id_flop;
    m_axis_read_data_tdest_int = axis_dest_flop;
    m_axis_read_data_tuser_int = axis_user_flop;

    m_axi_rready_next = 1'b0;

    transfer_in_save = 1'b0;
    axis_cmd_ready = 1'b0;

    offset_next = offset_flop;
    last_cycle_offset_next = last_cycle_offset_flop;
    input_cycle_count_next = input_cycle_count_flop;
    output_cycle_count_next = output_cycle_count_flop;
    input_active_next = input_active_flop;
    output_active_next = output_active_flop;
    bubble_cycle_next = bubble_cycle_flop;
    first_cycle_next = first_cycle_flop;
    output_last_cycle_next = output_last_cycle_flop;

    tag_next = tag_flop;
    axis_id_next = axis_id_flop;
    axis_dest_next = axis_dest_flop;
    axis_user_next = axis_user_flop;

    case (axis_state_flop)
        AXIS_STATE_IDLE: begin
            // idle state - load new descriptor to start operation
            m_axi_rready_next = 1'b0;

            // store transfer parameters
            if (ENABLE_UNALIGNED) begin
                offset_next = axis_cmd_offset_flop;
            end else begin
                offset_next = 0;
            end
            last_cycle_offset_next = axis_cmd_last_cycle_offset_flop;
            input_cycle_count_next = axis_cmd_input_cycle_count_flop;
            output_cycle_count_next = axis_cmd_output_cycle_count_flop;
            bubble_cycle_next = axis_cmd_bubble_cycle_flop;
            tag_next = axis_cmd_tag_flop;
            axis_id_next = axis_cmd_axis_id_flop;
            axis_dest_next = axis_cmd_axis_dest_flop;
            axis_user_next = axis_cmd_axis_user_flop;

            output_last_cycle_next = output_cycle_count_next == 0;
            input_active_next = 1'b1;
            output_active_next = 1'b1;
            first_cycle_next = 1'b1;

            if (axis_cmd_valid_flop) begin
                axis_cmd_ready = 1'b1;
                m_axi_rready_next = m_axis_read_data_tready_int_early;
                axis_state_next = AXIS_STATE_READ;
            end
        end
        AXIS_STATE_READ: begin
            // handle AXI read data
            m_axi_rready_next = m_axis_read_data_tready_int_early && input_active_flop;

            if (m_axis_read_data_tready_int_flop && ((m_axi_rready && m_axi_rvalid) || !input_active_flop)) begin
                // transfer in AXI read data
                transfer_in_save = m_axi_rready && m_axi_rvalid;

                if (ENABLE_UNALIGNED && first_cycle_flop && bubble_cycle_flop) begin
                    if (input_active_flop) begin
                        input_cycle_count_next = input_cycle_count_flop - 1;
                        input_active_next = input_cycle_count_flop > 0;
                    end
                    bubble_cycle_next = 1'b0;
                    first_cycle_next = 1'b0;

                    m_axi_rready_next = m_axis_read_data_tready_int_early && input_active_next;
                    axis_state_next = AXIS_STATE_READ;
                end else begin
                    // update counters
                    if (input_active_flop) begin
                        input_cycle_count_next = input_cycle_count_flop - 1;
                        input_active_next = input_cycle_count_flop > 0;
                    end
                    if (output_active_flop) begin
                        output_cycle_count_next = output_cycle_count_flop - 1;
                        output_active_next = output_cycle_count_flop > 0;
                    end
                    output_last_cycle_next = output_cycle_count_next == 0;
                    bubble_cycle_next = 1'b0;
                    first_cycle_next = 1'b0;

                    // pass through read data
                    m_axis_read_data_tdata_int = shift_axi_rdata;
                    m_axis_read_data_tkeep_int = {AXIS_KEEP_WIDTH_INT{1'b1}};
                    m_axis_read_data_tvalid_int = 1'b1;

                    if (output_last_cycle_flop) begin
                        // no more data to transfer, finish operation
                        if (last_cycle_offset_flop > 0) begin
                            m_axis_read_data_tkeep_int = {AXIS_KEEP_WIDTH_INT{1'b1}} >> (AXIS_KEEP_WIDTH_INT - last_cycle_offset_flop);
                        end
                        m_axis_read_data_tlast_int = 1'b1;

                        m_axis_read_desc_status_tag_next = tag_flop;
                        m_axis_read_desc_status_valid_next = 1'b1;

                        m_axi_rready_next = 1'b0;
                        axis_state_next = AXIS_STATE_IDLE;
                    end else begin
                        // more cycles in AXI transfer
                        m_axi_rready_next = m_axis_read_data_tready_int_early && input_active_next;
                        axis_state_next = AXIS_STATE_READ;
                    end
                end
            end else begin
                axis_state_next = AXIS_STATE_READ;
            end
        end
    endcase
end

/*
   Patch start
*/
    assign save_axi_rdata_flop_next = (transfer_in_save) ? m_axi_rdata : save_axi_rdata_flop;
/*
   Patch end
*/


always_ff @(posedge clk or posedge rst) begin

/*
    if (transfer_in_save) begin
        save_axi_rdata_flop <= m_axi_rdata;
    end
*/
    if (rst) begin
        save_axi_rdata_flop <= 0;
        axi_state_flop <= AXI_STATE_IDLE;
        axis_state_flop <= AXIS_STATE_IDLE;

        axis_cmd_valid_flop <= 1'b0;

        s_axis_read_desc_ready_flop <= 1'b0;

        m_axis_read_desc_status_valid_flop <= 1'b0;
    m_axis_read_desc_status_tag_flop <= 0;
    
        m_axi_arvalid_flop <= 1'b0;
        m_axi_rready_flop <= 1'b0;
    m_axi_araddr_flop <= 0;
    m_axi_arlen_flop <= 0;

    addr_flop <= 0;
    op_word_count_flop <= 0;
    tr_word_count_flop <= 0;

    axis_cmd_offset_flop <= 0;
    axis_cmd_last_cycle_offset_flop <= 0;
    axis_cmd_input_cycle_count_flop <= 0;
    axis_cmd_output_cycle_count_flop <= 0;
    axis_cmd_bubble_cycle_flop <= 0;
    axis_cmd_tag_flop <= 0;
    axis_cmd_axis_id_flop <= 0;
    axis_cmd_axis_dest_flop <= 0;
    axis_cmd_axis_user_flop <= 0;
    axis_cmd_valid_flop <= 0;

    offset_flop <= 0;
    last_cycle_offset_flop <= 0;
    input_cycle_count_flop <= 0;
    output_cycle_count_flop <= 0;
    input_active_flop <= 0;
    output_active_flop <= 0;
    bubble_cycle_flop <= 0;
    first_cycle_flop <= 0;
    output_last_cycle_flop <= 0;

    tag_flop <= 0;
    axis_id_flop <= 0;
    axis_dest_flop <= 0;
    axis_user_flop <= 0;
    end
    else begin
    axi_state_flop <= axi_state_next;
    axis_state_flop <= axis_state_next;

    s_axis_read_desc_ready_flop <= s_axis_read_desc_ready_next;

    m_axis_read_desc_status_valid_flop <= m_axis_read_desc_status_valid_next;
    m_axis_read_desc_status_tag_flop <= m_axis_read_desc_status_tag_next;

    m_axi_araddr_flop <= m_axi_araddr_next;
    m_axi_arlen_flop <= m_axi_arlen_next;
    m_axi_arvalid_flop <= m_axi_arvalid_next;
    m_axi_rready_flop <= m_axi_rready_next;

    addr_flop <= addr_next;
    op_word_count_flop <= op_word_count_next;
    tr_word_count_flop <= tr_word_count_next;

    axis_cmd_offset_flop <= axis_cmd_offset_next;
    axis_cmd_last_cycle_offset_flop <= axis_cmd_last_cycle_offset_next;
    axis_cmd_input_cycle_count_flop <= axis_cmd_input_cycle_count_next;
    axis_cmd_output_cycle_count_flop <= axis_cmd_output_cycle_count_next;
    axis_cmd_bubble_cycle_flop <= axis_cmd_bubble_cycle_next;
    axis_cmd_tag_flop <= axis_cmd_tag_next;
    axis_cmd_axis_id_flop <= axis_cmd_axis_id_next;
    axis_cmd_axis_dest_flop <= axis_cmd_axis_dest_next;
    axis_cmd_axis_user_flop <= axis_cmd_axis_user_next;
    axis_cmd_valid_flop <= axis_cmd_valid_next;

    offset_flop <= offset_next;
    last_cycle_offset_flop <= last_cycle_offset_next;
    input_cycle_count_flop <= input_cycle_count_next;
    output_cycle_count_flop <= output_cycle_count_next;
    input_active_flop <= input_active_next;
    output_active_flop <= output_active_next;
    bubble_cycle_flop <= bubble_cycle_next;
    first_cycle_flop <= first_cycle_next;
    output_last_cycle_flop <= output_last_cycle_next;

    tag_flop <= tag_next;
    axis_id_flop <= axis_id_next;
    axis_dest_flop <= axis_dest_next;
    axis_user_flop <= axis_user_next;
    save_axi_rdata_flop <= save_axi_rdata_flop_next;
    end
end

// output datapath logic
logic [AXIS_DATA_WIDTH-1:0] m_axis_read_data_tdata_flop, m_axis_read_data_tdata_flop_next;
logic [AXIS_KEEP_WIDTH-1:0] m_axis_read_data_tkeep_flop, m_axis_read_data_tkeep_flop_next;
logic                       m_axis_read_data_tvalid_flop, m_axis_read_data_tvalid_next;
logic                       m_axis_read_data_tlast_flop, m_axis_read_data_tlast_flop_next;
logic [AXIS_ID_WIDTH-1:0]   m_axis_read_data_tid_flop, m_axis_read_data_tid_flop_next;
logic [AXIS_DEST_WIDTH-1:0] m_axis_read_data_tdest_flop, m_axis_read_data_tdest_flop_next;
logic [AXIS_USER_WIDTH-1:0] m_axis_read_data_tuser_flop, m_axis_read_data_tuser_flop_next;

logic [AXIS_DATA_WIDTH-1:0] temp_m_axis_read_data_tdata_flop, temp_m_axis_read_data_tdata_flop_next;
logic [AXIS_KEEP_WIDTH-1:0] temp_m_axis_read_data_tkeep_flop, temp_m_axis_read_data_tkeep_flop_next;
logic                       temp_m_axis_read_data_tvalid_flop, temp_m_axis_read_data_tvalid_next;
logic                       temp_m_axis_read_data_tlast_flop, temp_m_axis_read_data_tlast_flop_next;
logic [AXIS_ID_WIDTH-1:0]   temp_m_axis_read_data_tid_flop, temp_m_axis_read_data_tid_flop_next;
logic [AXIS_DEST_WIDTH-1:0] temp_m_axis_read_data_tdest_flop, temp_m_axis_read_data_tdest_flop_next;
logic [AXIS_USER_WIDTH-1:0] temp_m_axis_read_data_tuser_flop, temp_m_axis_read_data_tuser_flop_next;

// datapath control
logic store_axis_int_to_output;
logic store_axis_int_to_temp;
logic store_axis_temp_to_output;

assign m_axis_read_data_tdata  = m_axis_read_data_tdata_flop;
assign m_axis_read_data_tkeep  = AXIS_KEEP_ENABLE ? m_axis_read_data_tkeep_flop : {AXIS_KEEP_WIDTH{1'b1}};
assign m_axis_read_data_tvalid = m_axis_read_data_tvalid_flop;
assign m_axis_read_data_tlast  = AXIS_LAST_ENABLE ? m_axis_read_data_tlast_flop : 1'b1;
assign m_axis_read_data_tid    = AXIS_ID_ENABLE   ? m_axis_read_data_tid_flop   : {AXIS_ID_WIDTH{1'b0}};
assign m_axis_read_data_tdest  = AXIS_DEST_ENABLE ? m_axis_read_data_tdest_flop : {AXIS_DEST_WIDTH{1'b0}};
assign m_axis_read_data_tuser  = AXIS_USER_ENABLE ? m_axis_read_data_tuser_flop : {AXIS_USER_WIDTH{1'b0}};

// enable ready input next cycle if output is ready or the temp logic will not be filled on the next cycle (output logic empty or no input)
assign m_axis_read_data_tready_int_early = m_axis_read_data_tready || (!temp_m_axis_read_data_tvalid_flop && (!m_axis_read_data_tvalid_flop || !m_axis_read_data_tvalid_int));

always_comb begin
    // transfer sink ready state to source
    m_axis_read_data_tvalid_next = m_axis_read_data_tvalid_flop;
    temp_m_axis_read_data_tvalid_next = temp_m_axis_read_data_tvalid_flop;

    store_axis_int_to_output = 1'b0;
    store_axis_int_to_temp = 1'b0;
    store_axis_temp_to_output = 1'b0;

    if (m_axis_read_data_tready_int_flop) begin
        // input is ready
        if (m_axis_read_data_tready || !m_axis_read_data_tvalid_flop) begin
            // output is ready or currently not valid, transfer data to output
            m_axis_read_data_tvalid_next = m_axis_read_data_tvalid_int;
            store_axis_int_to_output = 1'b1;
        end else begin
            // output is not ready, store input in temp
            temp_m_axis_read_data_tvalid_next = m_axis_read_data_tvalid_int;
            store_axis_int_to_temp = 1'b1;
        end
    end else if (m_axis_read_data_tready) begin
        // input is not ready, but output is ready
        m_axis_read_data_tvalid_next = temp_m_axis_read_data_tvalid_flop;
        temp_m_axis_read_data_tvalid_next = 1'b0;
        store_axis_temp_to_output = 1'b1;
    end
end
/*
   Patch start
*/
always_comb begin
   m_axis_read_data_tdata_flop_next = m_axis_read_data_tdata_flop;
   m_axis_read_data_tkeep_flop_next = m_axis_read_data_tkeep_flop;
   m_axis_read_data_tlast_flop_next = m_axis_read_data_tlast_flop;
   m_axis_read_data_tid_flop_next   = m_axis_read_data_tid_flop;
   m_axis_read_data_tdest_flop_next = m_axis_read_data_tdest_flop;
   m_axis_read_data_tuser_flop_next = m_axis_read_data_tuser_flop;
    if (store_axis_int_to_output) begin
        m_axis_read_data_tdata_flop_next = m_axis_read_data_tdata_int;
        m_axis_read_data_tkeep_flop_next = m_axis_read_data_tkeep_int;
        m_axis_read_data_tlast_flop_next = m_axis_read_data_tlast_int;
        m_axis_read_data_tid_flop_next   = m_axis_read_data_tid_int;
        m_axis_read_data_tdest_flop_next = m_axis_read_data_tdest_int;
        m_axis_read_data_tuser_flop_next = m_axis_read_data_tuser_int;
    end else if (store_axis_temp_to_output) begin
        m_axis_read_data_tdata_flop_next = temp_m_axis_read_data_tdata_flop;
        m_axis_read_data_tkeep_flop_next = temp_m_axis_read_data_tkeep_flop;
        m_axis_read_data_tlast_flop_next = temp_m_axis_read_data_tlast_flop;
        m_axis_read_data_tid_flop_next   = temp_m_axis_read_data_tid_flop;
        m_axis_read_data_tdest_flop_next = temp_m_axis_read_data_tdest_flop;
        m_axis_read_data_tuser_flop_next = temp_m_axis_read_data_tuser_flop;
    end
end

always_comb begin
   temp_m_axis_read_data_tdata_flop_next = temp_m_axis_read_data_tdata_flop;
   temp_m_axis_read_data_tkeep_flop_next = temp_m_axis_read_data_tkeep_flop;
   temp_m_axis_read_data_tlast_flop_next = temp_m_axis_read_data_tlast_flop;
   temp_m_axis_read_data_tid_flop_next   = temp_m_axis_read_data_tid_flop;
   temp_m_axis_read_data_tdest_flop_next = temp_m_axis_read_data_tdest_flop;
   temp_m_axis_read_data_tuser_flop_next = temp_m_axis_read_data_tuser_flop;
    if (store_axis_int_to_temp) begin
        temp_m_axis_read_data_tdata_flop_next = m_axis_read_data_tdata_int;
        temp_m_axis_read_data_tkeep_flop_next = m_axis_read_data_tkeep_int;
        temp_m_axis_read_data_tlast_flop_next = m_axis_read_data_tlast_int;
        temp_m_axis_read_data_tid_flop_next   = m_axis_read_data_tid_int;
        temp_m_axis_read_data_tdest_flop_next = m_axis_read_data_tdest_int;
        temp_m_axis_read_data_tuser_flop_next = m_axis_read_data_tuser_int;
    end
end


/*
   Patch end
*/

always @(posedge clk or posedge rst) begin
    if (rst) begin
        m_axis_read_data_tvalid_flop <= 1'b0;
        m_axis_read_data_tready_int_flop <= 1'b0;
        temp_m_axis_read_data_tvalid_flop <= 1'b0;
        
        m_axis_read_data_tdata_flop <= 0;
        m_axis_read_data_tkeep_flop <= 0;
        m_axis_read_data_tlast_flop <= 0;
        m_axis_read_data_tid_flop   <= 0;
        m_axis_read_data_tdest_flop <= 0;
        m_axis_read_data_tuser_flop <= 0;
        
       temp_m_axis_read_data_tdata_flop <= 0;
        temp_m_axis_read_data_tkeep_flop <= 0;
        temp_m_axis_read_data_tlast_flop <= 0;
        temp_m_axis_read_data_tid_flop   <= 0;
        temp_m_axis_read_data_tdest_flop <= 0;
        temp_m_axis_read_data_tuser_flop <= 0;
    end else begin
        m_axis_read_data_tvalid_flop <= m_axis_read_data_tvalid_next;
        m_axis_read_data_tready_int_flop <= m_axis_read_data_tready_int_early;
        temp_m_axis_read_data_tvalid_flop <= temp_m_axis_read_data_tvalid_next;
        
        m_axis_read_data_tdata_flop <= m_axis_read_data_tdata_flop_next;
        m_axis_read_data_tkeep_flop <= m_axis_read_data_tkeep_flop_next;
        m_axis_read_data_tlast_flop <= m_axis_read_data_tlast_flop_next;
        m_axis_read_data_tid_flop   <= m_axis_read_data_tid_flop_next;
        m_axis_read_data_tdest_flop <= m_axis_read_data_tdest_flop_next;
        m_axis_read_data_tuser_flop <= m_axis_read_data_tuser_flop_next;
        
       temp_m_axis_read_data_tdata_flop <= temp_m_axis_read_data_tdata_flop_next;
        temp_m_axis_read_data_tkeep_flop <= temp_m_axis_read_data_tkeep_flop_next;
        temp_m_axis_read_data_tlast_flop <= temp_m_axis_read_data_tlast_flop_next;
        temp_m_axis_read_data_tid_flop   <= temp_m_axis_read_data_tid_flop_next;
        temp_m_axis_read_data_tdest_flop <= temp_m_axis_read_data_tdest_flop_next;
        temp_m_axis_read_data_tuser_flop <= temp_m_axis_read_data_tuser_flop_next;
    end

    // datapath
/*
    if (store_axis_int_to_output) begin
        m_axis_read_data_tdata_flop <= m_axis_read_data_tdata_int;
        m_axis_read_data_tkeep_flop <= m_axis_read_data_tkeep_int;
        m_axis_read_data_tlast_flop <= m_axis_read_data_tlast_int;
        m_axis_read_data_tid_flop   <= m_axis_read_data_tid_int;
        m_axis_read_data_tdest_flop <= m_axis_read_data_tdest_int;
        m_axis_read_data_tuser_flop <= m_axis_read_data_tuser_int;
    end else if (store_axis_temp_to_output) begin
        m_axis_read_data_tdata_flop <= temp_m_axis_read_data_tdata_flop;
        m_axis_read_data_tkeep_flop <= temp_m_axis_read_data_tkeep_flop;
        m_axis_read_data_tlast_flop <= temp_m_axis_read_data_tlast_flop;
        m_axis_read_data_tid_flop   <= temp_m_axis_read_data_tid_flop;
        m_axis_read_data_tdest_flop <= temp_m_axis_read_data_tdest_flop;
        m_axis_read_data_tuser_flop <= temp_m_axis_read_data_tuser_flop;
    end
*/
/*
    if (store_axis_int_to_temp) begin
        temp_m_axis_read_data_tdata_flop <= m_axis_read_data_tdata_int;
        temp_m_axis_read_data_tkeep_flop <= m_axis_read_data_tkeep_int;
        temp_m_axis_read_data_tlast_flop <= m_axis_read_data_tlast_int;
        temp_m_axis_read_data_tid_flop   <= m_axis_read_data_tid_int;
        temp_m_axis_read_data_tdest_flop <= m_axis_read_data_tdest_int;
        temp_m_axis_read_data_tuser_flop <= m_axis_read_data_tuser_int;
    end
*/
end

endmodule
