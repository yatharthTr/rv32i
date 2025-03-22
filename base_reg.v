module base_reg(
    input [5:0]rs_addr_1,
    input [5:0]rs_addr_2,
    input clk,
    input [5:0]rd_addr,
    input [31:0]rd_val,
    input i_ce,
    // input [31:0]rd_val,
    input i_wenable,
    input i_renable,
    output [31:0]rs_val1,
    output [31:0]rs_val2
);

reg [31:0] reg_file[31:1];
reg [4:0] o_rs_addr_1;
reg [4:0] o_rs_addr_2;
always @(posedge clk) begin
  if(rd_addr && i_wenable) begin
    reg_file[rd_addr]<=rd_val;
  end
  if(i_renable) begin
    o_rs_addr_1<=rs_addr_1;
    o_rs_addr_2<=rs_addr_2;
    end
end
assign rs_val1=o_rs_addr_1==0?0:reg_file[rs_addr_1];
assign rs_val2=o_rs_addr_2==0?0:reg_file[rs_addr_2];
endmodule
