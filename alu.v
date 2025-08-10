// keep in mind that in JAL/JALR the register no. is mentioned in the instruction only


`include "rv_32_header.vh"
module alu(
    input clk, 
    input reset,
    input [4:0] i_rs1_addr,//from decode 
    output reg [4:0]o_rs1_addr,
    input [4:0] i_rs2_addr,//from decode
    input [31:0] i_rs1,//val from reg file
    input [31:0] i_rs2,//,,
    output reg [31:0] o_rs1,// to pipeline
    output reg [31:0] o_rs2,// to pipeline
    input i_ce,// 
    output reg [31:0] o_y,// result of arithmetic operation
    input [31:0] i_imm,// from decode
    output reg [11:0] o_imm,// to pipeline
    output reg o_ce,// to pipeline
    input i_stall,// from above stages
    output reg o_stall,// to pipeline
    input [`OPCODE_WIDTH-1:0] i_opcode,//from decode
    output reg [`OPCODE_WIDTH-1:0] o_opcode,// to pipeline
    input [`ALU_WIDTH-1:0] i_alu,// from decode
    // output reg [`ALU_WIDTH-1:0] o_alu,
    input i_force_stall,//
    output reg rd_reg_valid,// checks that valid rd or not
    output reg wr_reg_valid,// register write enable
    input i_flush,// from pipeline
    input [2:0]i_func3,// from decode
    output reg [2:0]o_func3,//to pipeline
    output reg o_flush,// to pipeline""" mostly previous stages"""
    input [31:0] i_pc,// from decoder
    output reg [31:0] o_pc,// to pipeline
    output reg [31:0] o_next_pc,// to fetch
    output reg  o_change_pc,//to fetch for changing pc signal 
    output reg o_stall_from_alu,// stall from alu "" mostly due to load signal 
    input [4:0] i_rd_adrr,// from decoder
    output reg[4:0] o_rd_addr,// to pipeline
    output reg[31:0] o_rd// to pipeline
    // output reg rd_enable
);


reg [31:0]out_sum;
wire [31:0]sum;
reg [31:0] rd_d;// this is the value that will be forwarded to the next stage by giving it to the o_rd, 
                // and its value will be designed in the last always block
reg [31:0] a_pc;// all for intermediate calculation as its final value will be given to  
reg [31:0] a, b;
reg wr_rd_d;
reg rd_valid_d;
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

// Restore the sum assignment for branch/jump calculation
assign sum=a_pc+i_imm;// for branch/jump

always @(posedge clk) begin
    if(reset) begin
        o_ce<=0;
        o_stall_from_alu<=0;
        o_change_pc<=0;
        o_stall<=0;// change kiya abhi
        o_rd <= 32'b0;  // Initialize ALU result to 0
        o_y <= 32'b0;   // Initialize ALU output to 0
        o_opcode <= 11'b0; // Initialize opcode to 0
        o_rd_addr <= 5'b0; // Initialize destination register address to 0
        rd_reg_valid <= 1'b0; // Initialize register valid signal to 0
        wr_reg_valid <= 1'b0; // Initialize write enable to 0
        o_stall_from_alu<=0;
    end
    else begin
        if(!stall_bit && i_ce) begin
            // o_ce<=i_ce;
            o_rd<=rd_d;
            o_y<=out_sum;
            o_func3<=i_func3;
            o_imm<=i_imm[11:0];
            o_opcode<=i_opcode;
            o_rs1<=i_rs1;
            o_rs2<=i_rs2;
            o_stall_from_alu <= i_opcode[`S_type] || i_opcode[`L_type];
            rd_reg_valid<=rd_valid_d;// enable jb ye valid destination register hai
            wr_reg_valid<=wr_rd_d;// its enabled if you have to write to the destination register
            // o_alu<=i_alu;
            o_pc<=i_pc;
            o_rs1_addr<=i_rs1_addr;
            o_rd_addr<=i_rd_adrr;
        end

        if(i_flush && !stall_bit) begin
            o_ce<=0;
        end

        else if(!stall_bit) o_ce<=i_ce;

        else if(stall_bit && !i_stall) begin// check
            o_ce<=0;
        end
    end

end

reg [31:0]store=0;

always @(*) begin


if (i_ce) begin
    
    a=opcode_jal || opcode_auipc ? i_pc:i_rs1;
    b=opcode_branch || opcode_rtype ? i_rs2:i_imm;

    out_sum = 32'b0;
    
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
else begin
    // If not enabled, use default values
    a = 32'b0;
    b = 32'b0;
    out_sum = 32'b0;


end
end

always @(*) begin
// if(reset) o_stall=0;
// else o_stall=(i_stall || i_force_stall) && (!i_flush);//change kiya abhi
o_flush=i_flush;
a_pc=i_pc;
o_stall=(i_stall || i_force_stall) && (!i_flush);
rd_valid_d=0;
wr_rd_d=0;
o_change_pc=0;
o_next_pc=0;
rd_d = 32'b0;  // Default value for ALU result

if(!i_flush) begin
    if(opcode_rtype || opcode_itype ) rd_d=out_sum;
    if(opcode_branch && out_sum[0]) begin
        o_next_pc=sum;
        o_change_pc=i_ce;  // $display("ALU_DEBUG: rs1=%h, rs2=%h, imm=%h, a=%h, b=%h, opcode=%b, alu_add=%b, alu_sub=%b, ce=%b", 
    //           i_rs1, i_rs2, i_imm, a, b, i_opcode, alu_add, alu_sub, i_ce);

    // Default value for out_sum to avoid 'x' when no operation matches
        o_flush=i_ce;
        // o_ce=0;
    end
    if(opcode_jal || opcode_jalr) begin
        if(opcode_jalr) a_pc=i_rs1;
        rd_d=i_pc+4;// returning address that has to be stored
        o_next_pc=sum;
        o_change_pc=i_ce;
        o_flush=i_ce;
    end


end
if(opcode_lui) rd_d=a_pc+i_imm;
if(opcode_auipc) rd_d=sum;

if(opcode_load) rd_valid_d=1'b0;// come back and check for store condn

else rd_valid_d=1'b1;

if(opcode_rtype || opcode_itype || opcode_load || opcode_jal || opcode_jalr) wr_rd_d=1'b1;

else wr_rd_d=0;

end

endmodule;
