// `define PC_RESET=32'd0;
// Instructions are getting feeded by testbench
module fetch_cycle(
    input clk,
    input reset,
    // input reg ce,
    output reg o_ce,
    output reg [31:0] out_addr,// to the instruction memory//changes kiya hai
    output wire out_req_inst,// requesting to the instruction memory
    input wire ack_req,// that your request has been acknowledged
    input wire alu_change_pc,// branch/jump has came
    input wire [31:0] new_pc,// from alu
    input wire [31:0] i_inst,//from inst memory
    output reg [31:0] o_inst,// to pipeline
    input wire i_stall,
    input wire iflush,
    output reg [31:0] o_pc// to the pipeline
);
parameter PC_RESET=32'd0;
reg [31:0] ip_addr,prev_pc,stalled_pc,stalled_inst;
wire stall_bit;
reg stall_fetch;
reg ce, ce_d;
reg stall_q;
reg branched_last_cycle;

assign stall_bit= i_stall||(out_req_inst && !ack_req) || (! out_req_inst);
assign out_req_inst = ce && !reset;



always @(posedge clk, posedge reset) begin
    if(reset) begin
        ce<=0;
        
    end
    else if(alu_change_pc && !i_stall) begin
        ce<=0;
        
    end
    else begin
        ce<=1'b1;
        
    end
end


always @(posedge clk, posedge reset) begin
    if(reset) begin
        out_addr<=0;
        o_pc<=0;
    end
    else begin
        if((!stall_bit && ce) || (stall_bit && !o_ce && ce) ) begin
           
            out_addr<=ip_addr;
            o_pc<=stall_q ? stalled_pc : prev_pc;
            o_inst<=stall_q ? stalled_inst : i_inst;
        end

        if(iflush && !stall_bit) begin
            o_ce<=0;
        end
        else if(!stall_bit) begin
            o_ce<=ce_d;
            
           
           
        end
        else if(stall_bit && (!i_stall)) o_ce<=0;// due to (out_req_inst && !ack_req) || (!out_req_inst);
        //                                        as the other stages already handle the situaton of i_stall, 
        //                                        meaning they are already in the stall, that's why they have 
        //                                        informed the previous stages to be stalled.
        // stall_q<=i_stall;// just consider this as one cycle delayed logic. 
        else o_ce<=0;
        stall_q<=i_stall || stall_fetch;
        if(stall_bit && !stall_q) begin
            stalled_pc<=prev_pc;// this is starting logc to refetch the same pc again n again till the stall ends
            stalled_inst<=i_inst;// same as above
        end
        prev_pc<=out_addr;

    end

end
always @(*) begin
    ip_addr=0;

    stall_fetch = i_stall;
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
