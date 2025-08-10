`timescale 1ns/1ps
`include "rv32i_core.v"
`include "rv_32_header.vh"
module rv32i_core_tb;

// Clock and Reset
reg clk;
reg rst;

// Instruction Memory Interface
wire [31:0] inst_addr;
wire        inst_req;
reg  [31:0] inst_data;
reg         inst_ack;

// Data Memory Interface
wire        data_cyc;
wire        data_we;
wire [31:0] data_addr;
wire [31:0] data_o;
reg  [31:0] data_i;
reg         data_ack;
wire        data_stb;

// Core Instantiation
core uut (
    .i_clk(clk),
    .i_rst(rst),
    .i_inst(inst_data),
    .o_addr(inst_addr),
    .o_stb_inst(inst_req),
    .i_ack(inst_ack),
    .o_wb_stb_data(data_stb),
    .o_wb_cyc_data(data_cyc),
    .o_wb_we_data(data_we),
    .o_wb_addr_data(data_addr),
    .o_wb_data(data_o),
    .i_wb_ack_data(data_ack),
    .i_wb_data(data_i)
);

// Clock Generation
initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

// Reset Generation
initial begin
    $dumpfile("rv32i_core_2tb.vcd");
    $dumpvars(0, rv32i_core_tb);
    rst = 1;
    inst_ack = 0;
    data_ack = 0;
    #20;
    rst = 0;
end

// Instruction Memory Simulation
reg [31:0] inst_mem [0:255];
initial begin
    // Initialize instruction memory
    // Program:
    // add x1, x2, x3
    // lw x4, 0(x1)
    // sw x4, 4(x1)
    // beq x1, x2, 16
    
    inst_mem[0] = 32'h003100b3; // ADD x1, x2, x3
    // inst_mem[1] = 32'h00a00293; // ADDI x5, x0, 10
    $display("TESTBENCH DEBUG: Instruction[0]=%h Instruction[1]=%h", inst_mem[0], inst_mem[1]);
    // inst_mem[2] = 32'h003100b3;
    inst_mem[1] = 32'h0040a423; // SW x4, 8(x1)
    inst_mem[2] = 32'h00a30293;//ADDI x5, x6, 10
    inst_mem[3] = 32'h0002a383; // LW x7, 0(x5)
    inst_mem[4] = 32'h4013c433; // SUB x8, x7, x1
    inst_mem[5] = 32'h003444b3; // AND x9, x8, x3
    inst_mem[6] = 32'h0024d533; // OR x10, x9, x2
    inst_mem[7] = 32'h00208663; // BEQ x1, x2, 16 (offset = 4 instructions ahead)
    inst_mem[8] = 32'h00529663; // BNE x5, x4, -4 (offset = -1 instruction)
    inst_mem[9] = 32'h0140056f; // JAL x11, 20 (jump 5 instructions ahead)
    // inst_mem[3] = 32'h00208663; // BEQ x1, x2, 12
    
    // // For debugging: Display contents of instruction memory
    // $display("DEBUG: Instruction Memory Contents:");
    // $display("DEBUG: inst_mem[0] = %h (ADD)", inst_mem[0]);
    // $display("DEBUG: inst_mem[1] = %h (LW)", inst_mem[1]);
    // $display("DEBUG: inst_mem[2] = %h (SW)", inst_mem[2]);
    // $display("DEBUG: inst_mem[3] = %h (BEQ)", inst_mem[3]);
end

// Instruction Memory Handler 
always @(posedge clk) begin
    if (rst) begin
        inst_ack <= 0;
        inst_data <= 0;
        $display("TB: Reset instruction memory");
    end
    else if (inst_req && !inst_ack) begin
        inst_data <= inst_mem[(inst_addr >> 2)];
        inst_ack <= 1;
        $display("TB: Fetching instruction at address %h (index %10d): %h", inst_addr, inst_addr >> 2, inst_mem[(inst_addr >> 2)]);
        
        // Detect instruction types for detailed debugging
        if (inst_mem[(inst_addr >> 2)][6:0] == 7'b0110011) begin
          $display("TB DEBUG: R-type instruction at %h", inst_addr);
        end
        else if (inst_mem[(inst_addr >> 2)][6:0] == 7'b0000011) begin
          $display("TB DEBUG: L-type (LOAD) instruction at %h", inst_addr);
          $display("TB CRITICAL: LW instruction fetched, next should be SW at 0x8: 0040a423");
        end
        else if (inst_mem[(inst_addr >> 2)][6:0] == 7'b0100011) begin
          $display("TB DEBUG: S-type (STORE) instruction at %h", inst_addr);
          $display("TB CRITICAL: SW instruction successfully fetched at 0x8!");
        end
        else begin
          $display("TB DEBUG: Unknown instruction type at %h: %h", inst_addr, inst_mem[(inst_addr >> 2)]);
        end
    end
    else begin
        inst_ack <= 0;
        if (!inst_req) $display("TB: No instruction request");
        else if (inst_ack) $display("TB: Instruction already acknowledged");
    end
end

// Data Memory Simulation
reg [31:0] data_mem [0:255];
initial begin
    // Initialize data memory
    data_mem[0] = 32'h12345678;
    data_mem[1] = 32'h9abcdef0;
    data_mem[17]=32'h9abcdef0;
end

// Data Memory Handler
always @(posedge clk) begin
    data_ack <= 0;
    data_i<=0;
    if (data_stb && data_cyc) begin
        if (data_we) begin
            #2; // Write delay
            data_mem[data_addr >> 2] <= data_o;
            $display("Data Write: Addr=%h Data=%h", data_addr, data_o);
        end
        else begin
            #2; // Read delay
            data_i <= data_mem[data_addr >> 2];
            $display("Data Read: Addr=%h Data=%h", data_addr, data_i);
        end
        data_ack <= 1;
    end
end

// Main Test Sequence
initial begin
    // Setup simulation
    $dumpfile("rv32i_core_1tb.vcd");
    $dumpvars(0, rv32i_core_tb);
    
    $display("Fetch: Holding PC at %h until acknowledged", inst_addr);
    
    // Initialize memory with test instructions
    // IMPORTANT: inst_mem[0] = R-type add
    // inst_mem[1] = LW (load word)
    // inst_mem[2] = SW (store word)
    // inst_mem[0] = 32'h003100b3;  // R-type add: add x1, x2, x3
    // inst_mem[1] = 32'h0000a203;// LW: lw x4, 0(x1)
    // inst_mem[2] = 32'h003100b3;  
    // inst_mem[2] = 32'h0040a423;  // SW: sw x4, 8(x1)
    // Add more test instructions as needed
    
    // $display("TB: Reset instruction memory");
    
    // // Add explicit dump of the instructions at their respective addresses
    // $display("TB: Instruction at address 0x0: %h (R-type)", inst_mem[0]);
    // $display("TB: Instruction at address 0x4: %h (LW)", inst_mem[1]);
    // $display("TB: Instruction at address 0x8: %h (SW)", inst_mem[2]);
    
    // Reset signals
    clk = 0;
    rst = 1;
    #10 rst = 0;
    
    // Run simulation for enough time to fetch several instructions
    // #100;
    
    // Explicit check at time 70 (after we should have fetched LW at 0x4)
    // #70;
    // $display("CRITICAL CHECK: At time=%0t, PC=%h, next instruction should be at 0x8", $time, inst_addr);
    // if (inst_addr == 32'h8) begin
    //   $display("SUCCESS: PC has advanced to 0x8 as expected!");
    // end else begin
    //   $display("FAILURE: PC is at %h instead of expected 0x8", inst_addr);
    // end
    
    // Run until end time
    #4820 $finish;
end

// Debugging: Track pipeline stages
always @(posedge clk) begin
    $display("--- Stage Status at time %0t ---", $time);
    $display("Fetch: PC=%h Instr=%h o_ce=%b stall_bit=%b out_req=%b ack=%b", 
        uut.o_addr, uut.f0.i_inst, uut.decoder_ce, uut.f0.stall_bit, uut.f0.out_req_inst, uut.f0.ack_req);
    $display("Fetch Internal: ce=%b ce_d=%b i_stall=%b", 
        uut.f0.ce, uut.f0.ce_d, uut.f0.i_stall);
    $display("Decode: decoder_Opcode=%b decode_pc=%h RS1=%h RS2=%h", 
        uut.decoder_opcode, uut.decoder_pc, uut.rs1_orig, uut.rs2_orig);
    $display("Decoder Internal: i_ce=%b stall_bit=%b i_inst=%h opcode_raw=%h", 
        uut.f0.o_ce, uut.d0.stall_bit, uut.d0.i_inst, uut.d0.opcode);
    $display("Decoder Types: r_type=%b i_type=%b branch=%b l_type=%b s_type=%b",
        uut.d0.r_type_d, uut.d0.i_type_d, uut.d0.branch_type_d, uut.d0.l_type_d, uut.d0.s_type_d);
    $display("Decoder ALU flags: alu_add=%b alu_sub=%b alu_and=%b alu_or=%b", 
        uut.d0.alu_add_d, uut.d0.alu_sub_d, uut.d0.alu_and_d, uut.d0.alu_or_d);
    $display("ALU: Result=%h", uut.alu_rd);
    $display("MEM: Addr=%h Data=%h", uut.o_wb_addr_data, uut.o_wb_data);
    $display("WB: RegWrite=%b Addr=%h Data=%h",
        uut.writeback_wr_rd, uut.writeback_rd_addr, uut.writeback_rd);
end

endmodule
