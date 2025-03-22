`include "rv_32_header.vh"
module core(
    input wire i_clk, i_rst,
    input wire [31:0] i_inst,
    output wire [31:0] o_addr,//pc
    output wire o_stb_inst//strobe
    input wire i_ack// ack_req in fetch
    output wire o_wb_stb_inst,//strobe signal
    output wire o_wb_cyc_data,
    output wire o_wb_we_data,
    output wire [31:0] o_wb_addr_data
    output wire [31:0] o_wb_data,// ye jaa rha wala data to store
    input wire i_wb_ack_data,
    input wire i_wb_stall_data,
    input wire [31:0] i_wb_data,// data from memory
);
// base reg part

wire [31:0] rs1_orig, rs2_orig,
wire [31:0] rs_1, rs_2/// this is feeded to the forward logic as an out put from hjere so that we can remove data hazard
wire ce_read // again feeded to base reg

// fetch

wire[31:0] fetch_pc;
wire[31:0] fetch_inst;

//decoder

wire [`ALU_WIDTH:0] decoder_alu;
wire[`OPCODE_WIDTH-1:0] decoder_opcode;
wire[31:0] decoder_pc;
wire[4:0] decoder_rs1_addr, decoder_rs2_addr;
wire[4:0] decoder_rs1_addr_q, decoder_rs2_addr_q;
wire[4:0] decoder_rd_addr; 
wire[31:0] decoder_imm;
wire[2:0] decoder_funct3;
wire decoder_ce;
wire decoder_flush;

//ALU

wire[`OPCODE_WIDTH-1:0] alu_opcode;
wire[4:0] alu_rs1_addr;
wire[31:0] alu_rs1;
wire[31:0] alu_rs2;
wire[11:0] alu_imm;
wire[2:0] alu_funct3;
wire[31:0] alu_y;
wire[31:0] alu_pc;
wire[31:0] alu_next_pc;
wire alu_change_pc;
wire alu_wr_rd;
wire[4:0] alu_rd_addr;
wire[31:0] alu_rd;
wire alu_rd_valid;
wire alu_ce;
wire alu_flush;

// MEM Stage

wire[`OPCODE_WIDTH-1:0] memoryaccess_opcode;
wire[2:0] memoryaccess_funct3;
wire[31:0] memoryaccess_pc;
wire memoryaccess_wr_rd;
wire[4:0] memoryaccess_rd_addr;
wire[31:0] memoryaccess_rd;
wire[31:0] memoryaccess_data_load;
wire memoryaccess_wr_mem;
wire memoryaccess_ce;
wire memoryaccess_flush;
wire o_stall_from_alu;

// Writeback

wire writeback_wr_rd; 
wire[4:0] writeback_rd_addr; 
wire[31:0] writeback_rd;
wire[31:0] writeback_next_pc;
wire writeback_change_pc;
wire writeback_ce;
wire writeback_flush;

wire stall_decoder,
wire stall_alu,
wire stall_memaccess,
wire stall_wb; 
assign ce_read = decoder_ce && !stall_decoder; 

base_reg b0(.rs_addr_1(decoder_rs1_addr),
.rs_addr_2(decoder_rs2_addr),
.clk(i_clk),
.rd_addr(writeback_rd_addr),
.rd_val(writeback_rd),
.rs_val1(.rs1_orig),
.rs_val2(.rs2_orig),
.i_renable(ce_read),
.i_wenable(writeback_wr_rd)
);

fetch_cycle f0(.clk(i_clk),
.reset(i_reset),
.o_ce(decoder_ce),
.out_req_inst(o_stb_inst),
.ack_req(i_ack),
.alu_change_pc(alu_change_pc),
.new_pc(alu_next_pc),
.i_inst(i_inst),
.o_inst(fetch_inst),
.i_stall(stall_decoder || stall_alu || stall_memaccess || stall_wb),
.iflush(decoder_flush),//
.o_pc(fetch_pc)
);

decode_it d0(.clk(i_clk),
.reset(i_reset),
.i_inst(fetch_inst),
.i_pc(fetch_pc),
.o_pc(decoder_pc),
.o_rs1_addr(decoder_rs1_addr),
.o_rs1_addr_d(decoder_rs1_addr_q),
.o_rs2_addr(decoder_rs2_addr),
.o_rs2_addr_d(decoder_rs2_addr_q),
.o_rd_addr(decoder_rd_addr),
// .o_rd_addr_d(),
.o_alu(decoder_alu),
.func_3(decoder_funct3),
.o_opcode(decoder_opcode),
.i_ce(decoder_ce),
.o_ce(alu_ce),
o_imm_d(decoder_imm),
i_stall(stall_alu || stall_memaccess || stall_wb),
i_flush(alu_flush),
o_stall(stall_decoder),
o_flush(decoder_flush)
)





