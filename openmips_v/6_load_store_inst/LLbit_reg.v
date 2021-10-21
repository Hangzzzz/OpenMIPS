`include "defines.v"
module LLbit_reg(
	input wire 				clk,
	input wire 				rst,
	//异常是否发生,1表示异常发生,0表示异常没有发生
	input wire 				flush,
	
	input wire 				LLbit_i,
	input wire 				we,
	
	output reg 				LLbit_o
	);
	
	always @(posedge clk ) begin
		if(rst == `RstEnable) begin
			LLbit_o <= 1'b0;
		end
		else if(flush == 1'b1) begin
			LLbit_o <= 1'b0;
		end	
		else if(we == `WriteEnable) begin
			LLbit_o <= LLbit_i;
		end
	end
	
endmodule
	