`include "rv_32_header.vh"
module alu(
    input clk, 
    input reset,
    input [4:0] i_rs1_addr,
    input [4:0] i_rs2_addr,
    input [31:0] i_rs1,
    input [31:0] i_rs2,
    input i_ce,
    input [31:0] i_imm,
    output reg o_ce,
    input i_stall,
    output reg o_stall,
    input [`OPCODE_WIDTH-1:0] i_opcode,
    output reg [`OPCODE_WIDTH-1:0] o_opcode,
    input [`ALU_WIDTH-1:0] i_alu,
    output reg [`ALU_WIDTH-1:0] o_alu,
    input i_force_stall,
    output reg rd_mem_valid,
    output reg wr_reg_valid,
    input i_flush,
    output reg o_flush,
    input [31:0] i_pc,
    output reg [31:0] o_pc,
    output reg [31:0] o_next_pc,
    output reg  o_change_pc,
    output reg o_stall_from_alu,
    input [4:0] i_rd_adrr,
    output reg[4:0] o_rd_addr,
    output reg[31:0] o_rd,
    output reg rd_enable
);


reg [31:0]out_sum;
wire [31:0]sum;
reg [31:0] rd_d;
reg [31:0] a_pc;
reg [31:0] a, b;
wire alu_add = i_alu[`ADD];
wire alu_sub = i_alu[`SUB];
wire alu_slt = i_alu[`SLT];
wire alu_sltu = i_alu[`SLTU];
wire alu_xor = i_alu[`XOR];
wire alu_or = i_alu[`OR];
wire alu_and = i_alu[`AND];
wire alu_sll = i_alu[`SLL];
wire alu_srl = i_alu[`SRL];
wire alu_sra = i_alu[`SRA];
wire alu_eq = i_alu[`BEQ];
wire alu_neq = i_alu[`BNEQ];
wire alu_ge = i_alu[`BGE];
wire alu_geu = i_alu[`BGEU];


wire opcode_rtype = i_opcode[`R_type];
wire opcode_itype = i_opcode[`I_type];
wire opcode_load = i_opcode[`L_type];
wire opcode_store = i_opcode[`S_type];
wire opcode_branch = i_opcode[`Branch_type];
wire opcode_jal = i_opcode[`JAL_type];
wire opcode_jalr = i_opcode[`JALR_type];
wire opcode_lui = i_opcode[`LUI_type];
wire opcode_auipc = i_opcode[`AUIPC_type];
wire opcode_system = i_opcode[`SYS_type];
wire opcode_fence = i_opcode[`F_type];
assign stall_bit=o_stall || i_stall;


always @(posedge clk, negedge reset) begin
    if(!reset) begin
        o_ce<=0;
        o_stall_from_alu<=0;
        o_change_pc<=0;
    end
    if(!stall_bit && i_ce) begin
        o_ce<=i_ce;
        o_rd<=rd_d;
        o_opcode<=i_opcode;
        o_alu<=i_alu;
        o_pc<=i_pc;
        o_rd_addr<=i_rd_adrr;
    end

    if(i_flush && !stall_bit) begin
        o_ce<=0;
    end

    else if(!stall_bit) o_ce<=i_ce;

    else if(stall_bit && !i_stall) begin
        o_ce<=0;
    end

end

reg [31:0]store=0;

always @(*) begin

a=opcode_jal || opcode_auipc ? i_pc:i_rs1_addr;

b=opcode_branch || opcode_rtype ? i_rs2_addr:i_imm;

if(alu_add) out_sum=a+b;
if(alu_sub) out_sum=a-b;
if(alu_xor) out_sum=a^b;
if(alu_or) out_sum=a|b;
if(alu_slt || alu_sltu) begin
    out_sum=(a<b)?{31'd0,1'b1}:32'd0;
    if(alu_slt) out_sum=((a[31]^b[31]) && a[31]==1'b1)?{31'b0,1'b1}:out_sum;
end
if(alu_and) out_sum=a & b;
if(alu_sll) out_sum=a<<b;
if(alu_srl) out_sum=a>>b;
if(alu_eq) out_sum=(a==b);
if(alu_neq) out_sum=!(a==b);
if(alu_ge || alu_geu) begin
    out_sum=(a>b);
    if(alu_ge) out_sum=(!a[31] | b[31])?32'd1:out_sum;
end
if(alu_sra) begin
    out_sum=$signed(a)>>>b;
end

end

assign sum=a_pc+i_imm;

always @(*) begin
o_flush=i_flush;
a_pc=i_pc;
o_stall=(i_stall || i_force_stall) && (!i_flush);
rd_mem_valid=0;
wr_reg_valid=0;
o_change_pc=0;
o_stall_from_alu=0;
o_stall=0;

if(!i_flush) begin
    if(opcode_rtype || opcode_itype ) rd_d=out_sum;
    if(opcode_branch && out_sum[0]) begin
        o_next_pc=sum;
        o_change_pc=i_ce;
        o_flush=i_ce;
        // o_ce=0;
    end
    if(opcode_jal || opcode_jalr) begin
        if(opcode_jalr) a_pc=i_rs1;
        rd_d=i_pc+3'd4;
        o_next_pc=sum;
        o_change_pc=i_ce;
        o_flush=i_ce;
    end
    if(opcode_lui) rd_d=a_pc+i_imm;
    if(opcode_auipc) rd_d=sum;

end

if(opcode_load || opcode_store) rd_mem_valid=1'b1;

else rd_mem_valid=0;

if(opcode_rtype || opcode_itype || opcode_load || opcode_jal || opcode_jalr) wr_reg_valid=1'b1;

else wr_reg_valid=0;

end

endmodule;
    




