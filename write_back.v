module wb(
    input wire [4:0] i_rd_addr,
    output reg [4:0]o_rd_addr,
    input wire i_ce,
    input wire i_wr_en,//enable signal for base register
    output reg o_wr_en,//out enable signal for base register
    input wire [31:0] i_rd,
    output reg [31:0] o_rd,
    input wire [31:0] i_mem_loaded,
    input wire i_opcode_load
);
always @(*) begin
    o_rd_addr=i_rd_addr;
    o_rd=0;
    o_wr_en=i_wr_en && i_ce;
    if(i_opcode_load) o_rd=i_mem_loaded;
    else o_rd=i_rd;
end
endmodule;
