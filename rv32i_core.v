`include "rv_32_header.vh"
`include "base_reg.v"
`include "fetch.v"
`include "decoder.v"
`include "alu.v"
`include "mem_access.v"
`include "write_back.v"
`include "forwarding_unit.v"
// `include "InstructionMemory.v"
module core(
    input wire i_clk, i_rst,
    input wire [31:0] i_inst,
    output wire [31:0] o_addr,//pc
    output wire o_stb_inst,//strobe
    output wire o_wb_stb_data,
    input wire i_ack,// ack_req in fetch
    output wire o_wb_stb_inst,//strobe signal
    output wire o_wb_cyc_data,
    output wire o_wb_we_data,
    output wire [31:0] o_wb_addr_data,
    output wire [31:0] o_wb_data,// data to be stored inside memory
    input wire i_wb_ack_data,
    input wire i_wb_stall_data,
    input wire [31:0] i_wb_data// data from memory
);
// base register part

wire [31:0] rs1_orig, rs2_orig;
wire [31:0] rs_1, rs_2;/// this is feeded to the forward logic as an out put from hjere so that we can remove data hazard
wire ce_read ;// again feeded to base reg
// wire [31:0] i_inst;
// fetch

wire[31:0] fetch_pc;
wire[31:0] fetch_inst;
// InstructionMemory m_InstMem(.readAddr(o_addr),
//     .inst(i_inst));

//decoder

wire [`ALU_WIDTH-1:0] decoder_alu;
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
wire writeback_ce;


wire stall_decoder;
wire stall_alu;
wire stall_memaccess;
wire stall_wb; 
assign stall_decoder=0;
assign stall_alu=0;
// assign stall_memaccess=0;
assign stall_wb=0;
assign ce_read = decoder_ce && !stall_decoder; 
base_reg b0(.rs_addr_1(decoder_rs1_addr),
.rs_addr_2(decoder_rs2_addr),
.clk(i_clk),
.rd_addr(writeback_rd_addr),
.rd_val(writeback_rd),
.rs_val1(rs1_orig),
.rs_val2(rs2_orig),
.i_renable(ce_read),
.i_wenable(writeback_wr_rd)
);
// fetch
assign alu_force_stall=0;
fetch_cycle f0(
.clk(i_clk),
.reset(i_rst),
.o_ce(decoder_ce),
.out_req_inst(o_stb_inst),// rewuest for data from instruction memory
.ack_req(i_ack),
.out_addr(o_addr),
.alu_change_pc(alu_change_pc),
.new_pc(alu_next_pc),
.i_inst(i_inst),
.o_inst(fetch_inst),
.i_stall(stall_decoder || stall_alu || stall_memaccess || stall_wb),
.iflush(decoder_flush),//
.o_pc(fetch_pc)
);
forwarding_unit f1(
    .rs1_value_original(rs1_orig),
    .rs2_value_original(rs2_orig),
    .rs1_address(decoder_rs1_addr_q),
    .rs2_address(decoder_rs2_addr_q),
    .stage4_enabled(memoryaccess_ce),
    .alu_result_valid(alu_rd_valid),
    .alu_write_reg(alu_wr_rd),
    .ex_mem_rd_address(alu_rd_addr),
    .ex_mem_rd_value(alu_rd),
    .stage5_enabled(writeback_ce),
    .stage5_write_reg(writeback_wr_rd),// valid 
    .mem_wb_rd_address(memoryaccess_rd_addr),
    .mem_wb_rd_value(memoryaccess_rd),
    .force_stall(alu_force_stall),
    .rs1_forwarded_value(rs_1),
    .rs2_forwarded_value(rs_2)
);
decode_it d0(.clk(i_clk),
.reset(i_rst),
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
.o_imm_d(decoder_imm),
.i_stall(stall_alu || stall_memaccess || stall_wb),
.i_flush(alu_flush),
.o_stall(stall_decoder),
.o_flush(decoder_flush)
);
alu a0(.clk(i_clk),
.reset(i_rst),
.i_rs1_addr(decoder_rs1_addr_q),
.i_rs2_addr(decoder_rs2_addr_q),
.i_rs1(rs_1),
.i_rs2(rs_2),
.o_rs1(alu_rs1),
.o_rs2(alu_rs2),
.i_ce(alu_ce),
.o_y(alu_y),
.i_imm(decoder_imm),
.o_imm(alu_imm),
.o_ce(memoryaccess_ce),
.i_stall(stall_memaccess || stall_wb),
.o_stall(stall_alu),
.i_opcode(decoder_opcode),
.o_opcode(alu_opcode),
.i_alu(decoder_alu),
// .o_alu(),
.i_force_stall(alu_force_stall),
.rd_reg_valid(alu_rd_valid),
.wr_reg_valid(alu_wr_rd),
.i_flush(memoryaccess_flush),
.i_func3(decoder_funct3),
.o_func3(alu_funct3),
.o_flush(alu_flush),
.i_pc(decoder_pc),
.o_pc(alu_pc),
.o_next_pc(alu_next_pc),
.o_change_pc(alu_change_pc),
.o_stall_from_alu(o_stall_from_alu),// this stall is for mem_stage,
.i_rd_adrr(decoder_rd_addr),
.o_rd_addr(alu_rd_addr),
.o_rd(alu_rd)
// .rd_enable()
);
memory_access m0(
.clk(i_clk),
.reset(i_rst),
.i_pc(alu_pc),
.i_rs2(alu_rs2),
.i_opcode(alu_opcode),
.i_wb_data_data(i_wb_data),
.o_opcode(memoryaccess_opcode),
.i_func3(alu_funct3),
.o_func3(memoryaccess_funct3),
.i_wr_rd(alu_wr_rd),
.o_wr_rd(memoryaccess_wr_rd),
.i_rd_addr(alu_rd_addr),
.i_rd_val(alu_rd),
.o_rd_val(memoryaccess_rd),
.o_rd_addr(memoryaccess_rd_addr),
.i_y(alu_y),
.o_pc(memoryaccess_pc),
.i_stall(stall_wb),
.i_flush(writeback_flush),
.o_flush(memoryaccess_flush),
.o_stall(stall_memaccess),
.i_stall_from_alu(o_stall_from_alu),
.i_ce(memoryaccess_ce),
.o_ce(writeback_ce),
.mem_ack(i_wb_ack_data),
.o_wb_cyc(o_wb_cyc_data),
.o_wb_we_data(o_wb_we_data),          
.o_wb_r_w_data(o_wb_stb_data), //requesting for memory or not       
.o_wb_addr_data(o_wb_addr_data),      
.o_wb_data_data(o_wb_data),        
.o_data_load(memoryaccess_data_load) // from memory to the register           
);
assign writeback_flush=0;
wb w0(.i_rd_addr(memoryaccess_rd_addr),
.o_rd_addr(writeback_rd_addr),
.i_ce(writeback_ce),
.i_wr_en(memoryaccess_wr_rd),
.o_wr_en(writeback_wr_rd),
.i_rd(memoryaccess_rd),
.o_rd(writeback_rd),
.i_mem_loaded(o_wb_data),
.i_opcode_load(memoryaccess_opcode[`L_type])
);
endmodule;
