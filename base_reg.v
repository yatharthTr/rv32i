module base_reg(
    input [4:0]rs_addr_1,
    input [4:0]rs_addr_2,
    input clk,
    input [4:0]rd_addr,
    input [31:0]rd_val,
    // input i_ce,
    // input [31:0]rd_val,
    input i_wenable,
    input i_renable,
    output [31:0]rs_val1,
    output [31:0]rs_val2
);

reg [31:0] reg_file[31:1];
reg [4:0] o_rs_addr_1;
reg [4:0] o_rs_addr_2;
integer i;
initial begin
    for (i = 1; i < 32; i = i + 1) begin
        reg_file[i] = i * 10;  
    end
end

always @(posedge clk) begin
  if(rd_addr && i_wenable) begin
    reg_file[rd_addr]<=rd_val;
  end
  if(i_renable) begin
    o_rs_addr_1<=rs_addr_1;
    o_rs_addr_2<=rs_addr_2;
  end
end
assign rs_val1=o_rs_addr_1==0?0:reg_file[o_rs_addr_1];
assign rs_val2=o_rs_addr_2==0?0:reg_file[o_rs_addr_2];
endmodule
