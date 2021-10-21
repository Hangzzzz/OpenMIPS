//=================================取指阶段================================================================================================================================
`include "defines.v"
module pc_reg(
	input wire				 clk,
	input wire				 rst,
	input wire[5:0]			 stall,						//来自控制模块CTRL
	output reg[`InstAddrBus] pc,						//要读取的指令地址
	output reg 				 ce 						//指令存储器使能信号
	);
	
	always @(posedge clk) begin
		if(rst == `RstEnable) 
			ce <= `ChipDisable;							//复位时指令存储器禁用
		else    										//复位结束后指令存储器使能
			ce <= `ChipEnable;
	end

	always @(posedge clk ) begin
		if (ce == `ChipDisable) begin
			pc <= 32'h00000000;							//指令存储器禁用时，pc的值为0
		end  										
		else if(stall[0] == `NoStop) begin
			pc <=pc + 4'h4;								//指令存储器使能时，pc的值每时钟周期+4
		end
	end
endmodule