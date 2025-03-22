// ALU CONTROL SIGNALS
`define ALU_WIDTH 14
`define ADD 0
`define SUB 1
`define SLL 2
`define SRL 3
`define SLT 4
`define AND 5
`define XOR 6
`define OR 7
`define SLTU 8
`define BEQ 9
`define BNEQ 10
`define BGE 11
`define SRA 12
`define BGEU 13

`define R_type 0
`define I_type 1
`define Branch_type 2
`define L_type 3
`define S_type 4
`define JAL_type 5
`define JALR_type 6
`define LUI_type 7
`define AUIPC_type 8
`define SYS_type 9
`define F_type 10
`define OPCODE_WIDTH 11


`define OPCODE_RTYPE 7'b0110011
`define OPCODE_ITYPE 7'b0010011
`define OPCODE_LTYPE 7'b0000011
`define OPCODE_STYPE 7'b0100011
`define OPCODE_BTYPE 7'b1100011
`define OPCODE_LUITYPE 7'b0110111
`define OPCODE_JALTYPE 7'b1101111
`define OPCODE_JALRTYPE 7'b1100111
`define OPCODE_AUIPCTYPE 7'b0010111
`define OPCODE_FTYPE 7'b0110011
`define OPCODE_RTYPE 7'b0001111


`define FUNC3_ADD 3'b000
`define FUNC3_SLL 3'b001
`define FUNC3_XOR 3'b100
// `define FUNC3_SRL 3'b101
`define FUNC3_SRA 3'b101
`define FUNC3_OR 3'b110
`define FUNC3_AND 3'b111
`define FUNC3_EQ 3'b000
`define FUNC3_NEQ 3'b001
`define FUNC3_LT 3'b100
`define FUNC3_GE 3'b101
`define FUNC3_LTU 3'b110
`define FUNC3_GEU 3'b111






