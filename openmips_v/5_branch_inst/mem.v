//=================================访存阶段==================================================================================================================================
`include "defines.v"
module mem(
	input wire 				rst,
	//来自执行阶段的信息
	input wire[`RegAddrBus]	wd_i,						//访存阶段的指令 要写入的目的寄存器地址
	input wire 				wreg_i,						//访存阶段的指令 是否有要写入的目的寄存器
	input wire[`RegBus]		wdata_i,					//访存阶段的指令 要写入的目的寄存器的值
	
	input wire[`RegBus]		hi_i,
	input wire[`RegBus]		lo_i,
	input wire				whilo_i,
	//访存阶段的结果
	output reg[`RegAddrBus]	wd_o,						//访存阶段的指令 最终 要写入的目的寄存器地址
	output reg 				wreg_o,						//访存阶段的指令 最终 是否有要写入的目的寄存器
	output reg[`RegBus]		wdata_o,					//访存阶段的指令 最终 要写入的目的寄存器的值
	
	output reg[`RegBus]		hi_o,
	output reg[`RegBus]		lo_o,
	output reg				whilo_o
	);
	always @(*) begin
		if (rst == `RstEnable) begin
			wd_o = `NOPRegAddr;
			wreg_o = `WriteDisable;
			wdata_o = `ZeroWord;
			hi_o 	= `ZeroWord;
			lo_o	= `ZeroWord;
			whilo_o = `WriteDisable;
		end
		else begin
			wd_o	= wd_i;
			wreg_o	= wreg_i;
			wdata_o = wdata_i;
			hi_o	= hi_i;
			lo_o	= lo_i;
			whilo_o	= whilo_i;
		end
	end
endmodule