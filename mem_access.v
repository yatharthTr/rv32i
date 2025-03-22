`include "rv_32_header.vh"
module memory_access(
    input clk, reset,
    input [31:0]i_pc,
    input [31:0]i_rs2,
    input [`OPCODE_WIDTH-1:0] i_opcode,
    input wire[31:0] i_wb_data_data,
    output reg [`OPCODE_WIDTH-1:0] o_opcode,
    input [2:0] i_func3,
    output reg [2:0] o_func3,
    input i_wr_rd,
    output reg o_wr_rd,
    input [4:0]i_rd_addr,
    input [31:0]i_rd_val,
    output reg[31:0] o_rd_val,
    output reg [4:0]o_rd_addr,
    input [31:0]i_y/// value from the alu (address)
    output reg  [31:0]o_pc,
    input i_stall,
    input i_flush,
    output reg o_flush,
    output reg o_stall,
    input i_ce,
    output reg o_ce,
    input wire mem_ack,
    output reg o_wb_cyc,
    output reg o_wb_we_data,
    output reg o_wb_r_w_data,// it tells whther you are requesting for memory access or not (read/write)
    output reg [31:0]o_wb_addr_data,
    output reg [31:0]o_wb_data_data,
    input [31:0]i_wb_data_data,
    output reg[31:0]o_data_load,
    output reg stall_from_mem
);
reg [31:0]data_store_d;
reg pending_ack;
reg [31:0]data_load_d;
wire stall_bit;
assign stall_bit=i_stall || o_stall;
always @(*) begin
    o_stall=!i_flush && (i_stall||(!mem_ack && i_ce && i_stall_from_alu));
    data_store_d=i_rs2;
    data_load_d=i_wb_data_data;
    o_flush=i_flush;
end

always @(posedge clk, negedge reset) begin
    if(!reset) begin
        pending_ack<=0;
        o_wb_r_w_data<=0;
        o_wb_we_data<=0;
        o_wb_cyc<=0;
        o_ce<=0;
        o_wr_rd<=0;


    end
    else begin
        o_wb_cyc<=i_ce;
        if(i_ce && !stall_bit) begin
            o_pc<=i_pc;
            o_ce<=i_ce;
            o_wr_rd<=i_wr_rd;
            o_rd_addr<=i_rd_addr;
            o_rd_val<=i_rd_val;
            
            o_data_load<=data_load_d;
            
            o_opcode<=i_opcode;
            o_func3<=i_func3;

        end
        if(mem_ack) begin
            pending_ack<=0;
        end
        if(i_flush && !stall_bit) o_ce<=0;
        if(!pending_ack && i_ce) begin
            pending_ack<=i_opcode[`L_type] || i_opcode[`S_type];
            o_wb_r_w_data<=i_opcode[`L_type] || i_opcode[`S_type];
            o_wb_we_data<=i_opcode[`S_type];
            o_wb_addr_data<=i_y;
            o_wb_data_data<=data_store_d;
        end
        if(pending_ack && !i_wb_stall_data) o_wb_r_w_data<=0;

        if(stall_bit && !i_stall) o_ce<=0;
        if(!stall_bit) o_ce<=i_ce;
    end
end