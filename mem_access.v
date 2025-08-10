`include "rv_32_header.vh"
module memory_access(
    input clk, reset,
    input [31:0]i_pc,// from alu
    input [31:0]i_rs2,// for storing of data in memory from alu
    input [`OPCODE_WIDTH-1:0] i_opcode,// from alu
    input wire[31:0] i_wb_data_data,// from memory that to be feeded to o_data_load at clock edge
    input wire i_wb_stall_data,// during writting it need to be stalled, it takes more clock cycles
    output reg [`OPCODE_WIDTH-1:0] o_opcode,// to pipeline
    input [2:0] i_func3,// from pipeline
    output reg [2:0] o_func3,// to pipeline
    input i_wr_rd,// from alu ,, reg write enable
    output reg o_wr_rd,// to pipeline
    input [4:0]i_rd_addr,// from alu
    input [31:0]i_rd_val,// from alu
    output reg[31:0] o_rd_val,// to pipeline
    output reg [4:0]o_rd_addr,// to pipeline
    input [31:0]i_y,/// value from the alu (address), in alu it o_y, for address to memory
    output reg  [31:0]o_pc,// to pipeline
    input i_stall,// from pipeline
    input i_flush,// from pipeline
    output reg o_flush,// to pipeline
    output reg o_stall,// to pipeline
    input i_ce, //from pipeline
    output reg o_ce, // to pipeline
    input wire mem_ack, //form data memory
    //signals feeded to data memory
    output reg o_wb_cyc,  // it is the bus cycle active signal, active when load/store signal, inactive only during flush 
    output reg o_wb_we_data,// memory write enable
    output reg o_wb_r_w_data,// it tells whether you are requesting for memory access or not (read/write)
    output reg [31:0]o_wb_addr_data,//to data memory, address feeded to data memory
    output reg [31:0]o_wb_data_data,// data feeded to data memory,stored
    // -----------------------------------------------------------
    input wire i_stall_from_alu,// from alu, when load/store intructions are there
    output reg[31:0]o_data_load,// data loaded for feeding to register form memory, to write back
    output reg stall_from_mem // mem stall, to pipeline
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

always @(posedge clk) begin
    if(reset) begin
        pending_ack<=0;
        o_wb_r_w_data<=0;
        o_wb_we_data<=0;
        o_wb_cyc<=0;
        o_ce<=0;
        o_wr_rd<=0;
        o_flush<=0;
        o_stall<=0;// change kiya abhi
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
        if(pending_ack && !i_wb_stall_data) o_wb_r_w_data<=0;//this means that the request has been acknowledge so we need to reset the o_wb_r_w_data
        if(!i_ce) o_wb_r_w_data<=0;
        if(stall_bit && !i_stall) o_ce<=0;
        if(!stall_bit) o_ce<=i_ce;
    end
end
endmodule;
