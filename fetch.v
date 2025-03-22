// `define PC_RESET=32'd0;
module fetch_cycle(
    input clk,
    input reset,
    // input reg ce,
    output reg o_ce,
    output wire out_req_inst,
    input wire ack_req,
    input wire alu_change_pc,
    input wire [31:0] new_pc,
    input wire [31:0] i_inst,
    output reg [31:0] o_inst,
    input wire i_stall,
    input wire iflush,
    output reg [31:0] o_pc
);
parameter PC_RESET=32'd0;
reg [31:0] out_addr,ip_addr,prev_pc,stalled_pc,stalled_inst;
wire stall_bit;
reg ce, ce_d;


assign stall_bit=i_stall || (out_req_inst && !ack_req) || (!out_req_inst);
reg stall_q;
always @(posedge clk, posedge reset) begin
    if(reset) begin
        ce<=0;
    end
    else if(alu_change_pc && !i_stall) ce<=0;
    else ce<=1'b1;
end
always @(posedge clk, posedge reset) begin
    if(reset) begin
        out_addr<=PC_RESET;
        o_ce<=0;
        prev_pc=PC_RESET;
        stalled_inst<=0;
        stalled_pc<=0;
    end
    else if((!stall_bit && ce) &&(stall_bit && !o_ce && ce) ) begin
        out_addr<=ip_addr;
        o_pc<=stall_q?stalled_pc:prev_pc;
        o_inst<=stall_q?stalled_inst:prev_pc;
    end
    else begin
        if(iflush && !stall_bit) begin
            o_ce<=0;
        end
        if(!stall_bit) o_ce<=ce_d;
        else if(stall_bit && (!i_stall)) o_ce<=0;
        stall_q<=i_stall;
        if(stall_bit && !stall_q) begin
            stalled_pc<=prev_pc;
            stalled_inst<=i_inst;
        end
        prev_pc<=out_addr;
    end

end
always @(*) begin
    ip_addr=0;
    if(alu_change_pc) begin
        ce_d=0;
        ip_addr=new_pc;
    end
    else begin
        ip_addr=out_addr+32'd4;
        ce_d=ce;
    end
end
endmodule
