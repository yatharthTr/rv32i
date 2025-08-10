`include "rv_32_header.vh"
module decode_it(
    input clk,reset,
    input wire [31:0] i_inst,// from fetch
    input wire[31:0] i_pc,//from fetch
    output reg[31:0] o_pc,// to pipeline
    output wire [4:0]o_rs1_addr,//dealt combinationally, directly feeded to register file
    output reg [4:0]o_rs1_addr_d,//to pipeline
    output wire [4:0]o_rs2_addr,
    output reg [4:0]o_rs2_addr_d,// store address for pipeline
    output reg [4:0]o_rd_addr,// to pipeline
    output reg [`ALU_WIDTH-1:0] o_alu,//to pipeline
    output reg [2:0]func_3,//to pipeline
    output reg [`OPCODE_WIDTH-1:0] o_opcode,//to pipeline
    input wire i_ce,// from 
    output reg o_ce,// to pipeline
    output reg [31:0] o_imm_d,//to pipeline
    input wire i_stall,//from pipeline
    input wire i_flush,//from pipeline
    output reg o_stall,// to pipeline
    output reg o_flush// to pipeline
);
wire[2:0] func_3_d=i_inst[14:12];
wire [6:0] opcode=i_inst[6:0];
assign o_rs1_addr=i_inst[19:15];
assign o_rs2_addr=i_inst[24:20];
reg alu_add_d;
reg alu_sub_d;
reg alu_sll_d;
reg alu_srl_d;
reg alu_sra_d;
reg alu_slt_d;
reg alu_and_d;
reg alu_xor_d;
reg alu_or_d;
reg alu_sltu_d;
reg alu_beq_d;
reg alu_bneq_d;
reg alu_bge_d;
reg alu_bgeu_d;

reg [31:0] i_imm_d;

reg r_type_d;
reg i_type_d;
reg branch_type_d;
reg l_type_d;
reg s_type_d;
reg jal_type_d;
reg jalr_type_d;
reg lui_type_d;
reg auipc_type_d;
reg sys_type_d;
reg fence_type_d;

wire stall_bit= i_stall || o_stall;


always @(posedge clk) begin
    if(reset) begin
        o_ce <= 0;
        o_stall <= 0;
        o_rs1_addr_d <= 5'b0;
        o_rs2_addr_d <= 5'b0;
        o_rd_addr <= 5'b0;
        o_pc <= 32'b0;
        o_imm_d <= 32'b0;
        o_opcode <= 11'b0;
        o_alu <= 14'b0;
        func_3 <= 3'b0;
        o_flush <= 0;
    end
    else begin
        if(i_ce && !stall_bit) begin
        // $display("Decoder: Processing instruction=%h, opcode=%h", i_inst, opcode);
        o_ce<=1'b1;
        o_pc<=i_pc;
        o_rs1_addr_d<=o_rs1_addr;
        o_rs2_addr_d<=o_rs2_addr;
        o_rd_addr<=i_inst[11:7];
        o_imm_d<=i_imm_d;
        func_3<=func_3_d;

        o_alu[`ADD]<=alu_add_d;
        o_alu[`SUB]<=alu_sub_d;
        o_alu[`SLL]<=alu_sll_d;
        o_alu[`SRL]<=alu_srl_d;
        o_alu[`SLT]<=alu_slt_d;
        o_alu[`AND]<=alu_and_d;
        o_alu[`XOR]<=alu_xor_d;
        o_alu[`OR]<=alu_or_d;
        o_alu[`SLTU]<=alu_sltu_d;
        o_alu[`BEQ]<=alu_beq_d;
        o_alu[`BNEQ]<=alu_bneq_d;
        o_alu[`BGE]<=alu_bge_d;
        o_alu[`SRA]<=alu_sra_d;
        o_alu[`BGEU]<=alu_bgeu_d;

        o_opcode[`R_type]<=r_type_d;
        o_opcode[`I_type]<=i_type_d;
        o_opcode[`Branch_type]<=branch_type_d;
        o_opcode[`L_type]<=l_type_d;
        o_opcode[`S_type]<=s_type_d;
        o_opcode[`JAL_type]<=jal_type_d;
        o_opcode[`JALR_type]<=jalr_type_d;
        o_opcode[`LUI_type]<=lui_type_d;
        o_opcode[`AUIPC_type]<=auipc_type_d;
        o_opcode[`SYS_type]<=sys_type_d;
        o_opcode[`F_type]<=fence_type_d;
      
    end
    if(i_flush && !stall_bit) begin
        o_ce<=0;
    end
    else if(!stall_bit) begin
        o_ce<=i_ce;
    end
    else if(stall_bit && !i_stall) begin
        o_ce<=0;
    end
end
end
always @(*) begin
        o_stall=i_stall;
        o_flush=i_flush;
        i_imm_d=0;
        alu_add_d=0;
        alu_sub_d=0;
        alu_sll_d=0;
        alu_srl_d=0;
        alu_sra_d=0;
        alu_slt_d=0;
        alu_and_d=0;
        alu_xor_d=0;
        alu_or_d=0;
        alu_sltu_d=0;
        alu_beq_d=0;
        alu_bneq_d=0;
        alu_bge_d=0;
        alu_bgeu_d=0;
        if(opcode==`OPCODE_RTYPE || opcode==`OPCODE_ITYPE) begin
            if(opcode==`OPCODE_RTYPE) begin
                // alu_add_d=(func_3_d==`FUNC3_ADD && !i_inst[30])?1:0;
                alu_add_d = func_3_d == `FUNC3_ADD ? !i_inst[30] : 0; //ad
                // alu_sub_d=!alu_add_d;
                alu_sub_d = func_3_d == `FUNC3_ADD ? i_inst[30] : 0;     //(func_3_d==`FUNC3_ADD && i_inst[30])
            end
            else begin
                alu_add_d=(func_3_d==`FUNC3_ADD);
            end
            alu_sll_d=func_3_d==`FUNC3_SLL ? 1:0;
            alu_srl_d=(func_3_d==`FUNC3_SRA && i_inst[30])  ? 1:0;
            alu_sra_d=(func_3_d==`FUNC3_SRA && !alu_srl_d);
            alu_slt_d=func_3_d==`FUNC3_LT ? 1:0;
            alu_and_d= func_3_d==`FUNC3_AND ? 1:0;
            alu_xor_d=func_3_d==`FUNC3_XOR ? 1:0;
            alu_or_d=func_3_d==`FUNC3_OR ? 1:0;
            alu_sltu_d=func_3_d==`FUNC3_LTU ? 1:0;
           
        end
        else if(opcode==`OPCODE_BTYPE) begin
            alu_slt_d=func_3_d==`FUNC3_LT ? 1:0;
            alu_sltu_d=func_3_d==`FUNC3_LTU ? 1:0;
            alu_beq_d=func_3_d==`FUNC3_EQ ? 1:0;
            alu_bneq_d=func_3_d==`FUNC3_NEQ ? 1:0;
            alu_bge_d=func_3_d==`FUNC3_GE ? 1:0;
            alu_bgeu_d=func_3_d==`FUNC3_GEU ? 1:0;
        end
        else alu_add_d=1'b1;

        r_type_d = (opcode==`OPCODE_RTYPE);
        i_type_d = (opcode==`OPCODE_ITYPE);
        branch_type_d = (opcode==`OPCODE_BTYPE);
        l_type_d = (opcode==`OPCODE_LTYPE);
        s_type_d=(opcode==`OPCODE_STYPE);

        jal_type_d=(opcode==`OPCODE_JALTYPE);
        jalr_type_d=opcode==`OPCODE_JALRTYPE;
        lui_type_d=opcode==`OPCODE_LUITYPE;
        auipc_type_d=(opcode==`OPCODE_AUIPCTYPE);
        sys_type_d=opcode==`OPCODE_SYSTEM;
        fence_type_d=opcode==`OPCODE_FTYPE;

        case(opcode)
            `OPCODE_ITYPE , `OPCODE_LTYPE , `OPCODE_JALRTYPE:i_imm_d = {{20{i_inst[31]}},i_inst[31:20]}; 
            `OPCODE_STYPE: i_imm_d = {{21{i_inst[31]}},i_inst[30:25],i_inst[11:7]};
            `OPCODE_BTYPE: i_imm_d = {{20{i_inst[31]}},i_inst[7],i_inst[30:25],i_inst[11:8],1'b0};
            `OPCODE_JALTYPE: i_imm_d = {{12{i_inst[31]}},i_inst[19:12],i_inst[20],i_inst[30:21],1'b0};
            `OPCODE_LUITYPE , `OPCODE_AUIPCTYPE: i_imm_d = {i_inst[31:12],12'h000};
            `OPCODE_FTYPE: i_imm_d = {20'b0,i_inst[31:20]};   
            default: i_imm_d = 0;
        endcase;
    end

endmodule;      
